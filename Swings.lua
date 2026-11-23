-- Swing rows follow the weapons in hand. Empty hands use the unarmed swing.
-- A two-hand weapon is one melee row. A bow, gun, or wand keeps its own row.
-- Dual wield is the main hand, then the off hand.
-- Forever reports each swing through PLAYER_SWING. Era still uses the combat log.

DiveBar = DiveBar or {}

local MAIN_SLOT = 16
local OFF_SLOT = 17
local RANGED_SLOT = 18
local AUTO_SHOT = 75
local WAND_SHOT = 5019
local INV_WEAPON = 13
local INV_SHIELD = 14
local INV_RANGED = 15
local INV_2H = 17
local INV_MAINHAND = 21
local INV_OFFHAND = 22
local INV_HOLDABLE = 23
local INV_THROWN = 25
local INV_RANGEDRIGHT = 26

local function Secret(value)
	return issecretvalue and issecretvalue(value) and true or false
end

local function PlainNumber(value)
	if Secret(value) or type(value) ~= "number" then
		return nil
	end
	return value
end

local function PlainFlag(value)
	if Secret(value) then
		return nil
	end
	if value == true or value == 1 then
		return true
	end
	if value == false or value == 0 then
		return false
	end
	return nil
end

function DiveBar:EnsureTimers()
	if self.timers then
		return
	end
	self.timers = {
		melee = {},
		off = {},
		ranged = {},
	}
	self.equipped = {}
end

-- nil, false: empty slot. nil, true: the id could not be read, so keep the old rows.
local function SlotItemID(slot)
	if type(GetInventoryItemID) ~= "function" then
		return nil, true
	end
	local ok, id = pcall(GetInventoryItemID, "player", slot)
	if not ok or Secret(id) then
		return nil, true
	end
	id = PlainNumber(id)
	if not id or id <= 0 then
		return nil, false
	end
	return id, false
end

local function InventoryType(item)
	if not (C_Item and C_Item.GetItemInventoryTypeByID) then
		return nil
	end
	local ok, value = pcall(C_Item.GetItemInventoryTypeByID, item)
	if not ok then
		return nil
	end
	return PlainNumber(value)
end

-- kind is nil while the item cache is cold. "empty" means that slot has no item.
-- twoHand is only meaningful once the item resolved.
local function ItemFacts(item)
	if not item then
		return "empty", false
	end
	local invType = InventoryType(item)
	local instant = GetItemInfoInstant
	if C_Item and C_Item.GetItemInfoInstant then
		instant = C_Item.GetItemInfoInstant
	end
	local equipLoc, classID, subclassID
	if instant then
		local ok, a, b, c, d, e, f, g = pcall(instant, item)
		if ok then
			if type(a) == "table" then
				equipLoc = a.itemEquipLoc or a.equipLoc or a.inventoryType
				classID = a.classID
				subclassID = a.subclassID
			else
				-- itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
				equipLoc, classID, subclassID = d, f, g
			end
		end
	end
	if not tonumber(classID) and GetItemInfo then
		local ok, _, _, _, _, _, _, _, _, loc, _, _, class, sub = pcall(GetItemInfo, item)
		if ok then
			equipLoc = equipLoc or loc
			classID = classID or class
			subclassID = subclassID or sub
		end
	end
	local twoHand = invType == INV_2H
	if tonumber(classID) then
		local kind = DiveBar.ClassifyItem(classID, subclassID, equipLoc)
		if DiveBar.IsTwoHanded(classID, subclassID, equipLoc) then
			twoHand = true
		end
		if invType == INV_SHIELD or invType == INV_HOLDABLE then
			kind = "none"
			twoHand = false
		elseif twoHand then
			kind = "melee"
		end
		return kind, twoHand
	end
	if twoHand then
		return "melee", true
	end
	if invType == INV_SHIELD or invType == INV_HOLDABLE then
		return "none", false
	end
	if invType == INV_WEAPON or invType == INV_MAINHAND or invType == INV_OFFHAND then
		return "melee", false
	end
	if invType == INV_RANGED or invType == INV_THROWN or invType == INV_RANGEDRIGHT then
		return "shot", false
	end
	return nil, false
end

function DiveBar:AttackSpeeds()
	if type(UnitAttackSpeed) ~= "function" then
		return nil, nil, nil
	end
	local ok, main, off, ranged = pcall(UnitAttackSpeed, "player")
	if not ok then
		return nil, nil, nil
	end
	return PlainNumber(main), PlainNumber(off), PlainNumber(ranged)
end

function DiveBar:ReadGear()
	self:EnsureTimers()
	local mainID, mainMiss = SlotItemID(MAIN_SLOT)
	local offID, offMiss = SlotItemID(OFF_SLOT)
	local rangedID, rangedMiss = SlotItemID(RANGED_SLOT)
	if mainMiss or offMiss or rangedMiss then
		return
	end
	local mainSpeed, offSpeed, rangedSpeed = self:AttackSpeeds()
	local mainKind, mainTwo = ItemFacts(mainID)
	local offKind, offTwo = ItemFacts(offID)
	local rangedKind = ItemFacts(rangedID)
	local twoHand = mainTwo or offTwo
	if not twoHand and type(IsEquippedItemType) == "function" and INVTYPE_2HWEAPON then
		local ok, worn = pcall(IsEquippedItemType, INVTYPE_2HWEAPON)
		if ok and PlainFlag(worn) then
			twoHand = true
		end
	end

	if mainKind == nil then
		mainKind = (mainSpeed and mainSpeed > 0) and "melee" or "none"
	elseif mainKind == "empty" then
		mainKind = "unarmed"
	end

	-- One off-hand bar only when the game reports a second swing speed.
	-- A two-hander, a shield, and empty hands do not.
	if twoHand or not (offSpeed and offSpeed > 0) then
		offKind = "none"
	else
		offKind = "melee"
	end

	if rangedKind == nil or rangedKind == "empty" or rangedKind == "none" then
		if not (rangedSpeed and rangedSpeed > 0) and type(UnitRangedDamage) == "function" then
			local ok, speed = pcall(UnitRangedDamage, "player")
			if ok then
				rangedSpeed = PlainNumber(speed)
			end
		end
		-- Forever reports the bow on UnitAttackSpeed's third value, even with a two-hander equipped.
		if rangedSpeed and rangedSpeed > 0 then
			rangedKind = "shot"
		else
			rangedKind = "none"
		end
	end

	self.equipped = self.RowsFromGear(mainKind, offKind, rangedKind, twoHand)
end

function DiveBar:GetVisibleSwingKeys()
	self:EnsureTimers()
	return DiveBar.VisibleRows(self.profile, self.equipped)
end

function DiveBar:HasRow(key)
	local rows = self.equipped or {}
	for i = 1, #rows do
		if rows[i] == key then
			return true
		end
	end
	return false
end

function DiveBar:RetargetSpeed(timer, speed)
	if not speed or speed <= 0 then
		timer.speed = speed
		return
	end
	if timer.running and timer.speed and timer.speed > 0 and timer.remaining and timer.remaining > 0 then
		timer.remaining = timer.remaining * (speed / timer.speed)
	end
	timer.speed = speed
end

function DiveBar:UpdateSpeeds()
	self:EnsureTimers()
	local main, off, ranged = self:AttackSpeeds()
	self:RetargetSpeed(self.timers.melee, main)
	self:RetargetSpeed(self.timers.off, off)
	if not (ranged and ranged > 0) and type(UnitRangedDamage) == "function" then
		local ok, speed = pcall(UnitRangedDamage, "player")
		if ok then
			ranged = PlainNumber(speed)
		end
	end
	self:RetargetSpeed(self.timers.ranged, ranged)
end

function DiveBar:SpellIsCurrent(spellID, spellName)
	local function ask(fn, arg)
		if type(fn) ~= "function" or arg == nil then
			return nil
		end
		local ok, value = pcall(fn, arg)
		if not ok then
			return nil
		end
		return PlainFlag(value)
	end
	if ask(IsCurrentSpell, spellID) or ask(IsCurrentSpell, spellName) then
		return true
	end
	if C_Spell and ask(C_Spell.IsCurrentSpell, spellID) then
		return true
	end
	return false
end

function DiveBar:Attacking()
	-- PLAYER_ENTER_COMBAT sets this. Polling IsCurrentSpell can throw when
	-- the result is secret, which stopped the swing fill entirely.
	if self.meleeHeld then
		return true
	end
	return self:SpellIsCurrent(6603, "Attack")
end

function DiveBar:Repeating()
	local function on(fn, arg)
		if type(fn) ~= "function" or arg == nil then
			return false
		end
		local ok, value = pcall(fn, arg)
		return ok and PlainFlag(value) == true
	end
	local spell = C_Spell and C_Spell.IsAutoRepeatSpell
	if on(spell, AUTO_SHOT) or on(spell, WAND_SHOT) or on(spell, "Auto Shot") or on(spell, "Shoot") then
		return true
	end
	return on(IsAutoRepeatSpell, AUTO_SHOT) or on(IsAutoRepeatSpell, WAND_SHOT) or on(IsAutoRepeatSpell, "Auto Shot") or on(IsAutoRepeatSpell, "Shoot")
end

function DiveBar:RangedActive()
	-- A melee swing takes the slot immediately. A finished shot must not keep it.
	if self:SwingInUse("melee") or self:SwingInUse("off") then
		return false
	end
	if self.repeating or self:Repeating() then
		return true
	end
	return self:SwingInUse("shot") or self:SwingInUse("wand")
end

function DiveBar:SpellInRange(spellID, spellName)
	if not UnitExists("target") then
		return false
	end
	local function ask(fn, a, b)
		if type(fn) ~= "function" then
			return nil
		end
		local ok, value = pcall(fn, a, b)
		if not ok then
			return nil
		end
		return PlainFlag(value)
	end
	-- Either API may be the one that knows. Out of range wins, so a false
	-- result is not discarded. Unknown stays unknown.
	local classic = ask(IsSpellInRange, spellName, "target")
	if classic == nil then
		classic = ask(IsSpellInRange, spellID, "target")
	end
	local modern
	if C_Spell then
		modern = ask(C_Spell.IsSpellInRange, spellID, "target")
	end
	if classic == false or modern == false then
		return false
	end
	if classic == true or modern == true then
		return true
	end
	return nil
end

function DiveBar:MeleeReachable()
	local ok, result = pcall(function()
		if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
			return false
		end
		return DiveBar:SpellInRange(6603, "Attack")
	end)
	if not ok then
		return nil
	end
	return result
end

function DiveBar:PauseTimer(timer)
	if timer.start and not timer.pausedAt then
		timer.pausedAt = GetTime()
	end
end

function DiveBar:ResumeTimer(timer)
	if not timer.speed or timer.speed <= 0 then
		return
	end
	local now = GetTime()
	if timer.pausedAt and timer.start then
		timer.start = timer.start + (now - timer.pausedAt)
		timer.pausedAt = nil
		return
	end
	if not timer.start then
		timer.start = now
	end
end

function DiveBar:ArmTimer(timer, speed)
	if speed and speed > 0 then
		timer.speed = speed
	end
	local duration = timer.speed
	if not duration or duration <= 0 then
		duration = 2
		timer.speed = duration
	end
	timer.running = true
	timer.remaining = duration
end

function DiveBar:AdvanceSwing(elapsed)
	if type(elapsed) ~= "number" or elapsed <= 0 then
		return
	end
	if elapsed > 0.2 then
		elapsed = 0.2
	end
	self:EnsureTimers()
	local function step(timer)
		if not timer.running or not timer.remaining or timer.remaining <= 0 then
			return
		end
		timer.remaining = timer.remaining - elapsed
		-- A finished swing is an empty bar. Leaving remaining at 0 kept the fill at full.
		if timer.remaining <= 0 then
			timer.remaining = 0
			timer.running = false
			if timer == self.timers.ranged and not self:Repeating() then
				self.repeating = false
			end
		end
	end
	step(self.timers.melee)
	step(self.timers.off)
	step(self.timers.ranged)
end

function DiveBar:StartMelee()
	self.repeating = false
	self.meleeHeld = true
	self:EnsureTimers()
	self:UpdateSpeeds()
	self:RequestTick()
	self:Refresh()
end

function DiveBar:StopMelee()
	self.meleeHeld = false
	self:EnsureTimers()
	self.timers.melee.start = nil
	self.timers.melee.pausedAt = nil
	self.timers.off.start = nil
	self.timers.off.pausedAt = nil
	self:Refresh()
end

function DiveBar:StartRanged()
	self.repeating = true
	self:EnsureTimers()
	self:UpdateSpeeds()
	self:RequestTick()
	self:Refresh()
end

function DiveBar:StopRanged()
	self.repeating = false
	self:EnsureTimers()
	self.timers.ranged.start = nil
	self.timers.ranged.pausedAt = nil
	self:Refresh()
end

function DiveBar:SyncAttack()
	self:EnsureTimers()
	if self:Attacking() then
		self:StartMelee()
	end
	if self:Repeating() then
		self:StartRanged()
	end
end

function DiveBar:SwingInUse(key)
	self:EnsureTimers()
	local timer = (key == "shot" or key == "wand") and self.timers.ranged or self.timers[key]
	return timer and timer.running and (timer.remaining or 0) > 0 and true or false
end

function DiveBar:SwingProgress(key)
	self:EnsureTimers()
	local timer = (key == "shot" or key == "wand") and self.timers.ranged or self.timers[key]
	if not timer or not timer.running or not timer.speed or timer.speed <= 0 then
		return 0
	end
	local remaining = timer.remaining or 0
	if remaining < 0 then
		remaining = 0
	elseif remaining > timer.speed then
		remaining = timer.speed
	end
	return 1 - (remaining / timer.speed)
end

function DiveBar:OnPlayerSwing(offhand)
	self.repeating = false
	self:EnsureTimers()
	self:UpdateSpeeds()
	local which = "melee"
	if offhand == true and self:HasRow("off") then
		which = "off"
	elseif offhand == nil and self:HasRow("off") then
		local function left(timer)
			if not timer.running then
				return 2
			end
			return timer.remaining or 0
		end
		if left(self.timers.off) < left(self.timers.melee) then
			which = "off"
		end
	end
	local main, off = self:AttackSpeeds()
	self:ArmTimer(self.timers[which], which == "off" and off or main)
	self:RequestTick()
end

function DiveBar:OnParryHaste()
	self:EnsureTimers()
	local timer = self.timers.melee
	if not timer.running or not timer.speed or timer.speed <= 0 then
		return
	end
	local remaining = timer.remaining or 0
	remaining = math.max(timer.speed * 0.2, remaining - timer.speed * 0.4)
	timer.remaining = remaining
	self:RequestTick()
end

function DiveBar:OnShotFired()
	if not self:Repeating() then
		return
	end
	self:EnsureTimers()
	self:UpdateSpeeds()
	local ranged = self.timers.ranged.speed
	if type(UnitRangedDamage) == "function" then
		local ok, speed = pcall(UnitRangedDamage, "player")
		if ok then
			ranged = PlainNumber(speed) or ranged
		end
	end
	self:ArmTimer(self.timers.ranged, ranged)
	self:RequestTick()
end

function DiveBar:IsPlayerGUID(guid, flags)
	local player = UnitGUID and UnitGUID("player") or nil
	if not Secret(guid) and not Secret(player) and type(guid) == "string" and guid == player then
		return true
	end
	if type(flags) ~= "number" or Secret(flags) or not (bit and bit.band) then
		return false
	end
	local mine = COMBATLOG_OBJECT_AFFILIATION_MINE or 1
	return bit.band(flags, mine) > 0
end

function DiveBar:UsesSwingEvent()
	local kinds = Enum and Enum.PlayerSwingType
	if kinds and kinds.MainHand ~= nil and kinds.OffHand ~= nil and kinds.Ranged ~= nil then
		return true
	end
	if C_EventUtils and C_EventUtils.IsEventValid then
		local ok, valid = pcall(C_EventUtils.IsEventValid, "PLAYER_SWING")
		if ok then
			return valid and true or false
		end
	end
	return false
end

-- swingDuration is seconds until that hand lands. A large value is milliseconds.
function DiveBar:OnSwingEvent(duration, swingType)
	if Secret(duration) or Secret(swingType) or type(duration) ~= "number" then
		return
	end
	if duration > 20 then
		duration = duration / 1000
	end
	if duration < 0 then
		return
	end
	local kinds = Enum and Enum.PlayerSwingType
	local key = "melee"
	local offType = kinds and kinds.OffHand or 1
	local rangedType = kinds and kinds.Ranged or 2
	if swingType == offType then
		key = "off"
	elseif swingType == rangedType then
		key = "ranged"
	end
	self:EnsureTimers()
	self:UpdateSpeeds()
	local timer = self.timers[key]
	if not timer then
		return
	end
	if duration <= 0 then
		return
	end
	if key ~= "ranged" then
		self.repeating = false
	end
	-- The event duration is the whole bar, so the fill starts empty.
	timer.speed = duration
	timer.running = true
	timer.remaining = duration
	self:RequestTick()
	self:Refresh()
end

function DiveBar:OnCombatLog()
	if self:UsesSwingEvent() then
		return
	end
	if type(CombatLogGetCurrentEventInfo) ~= "function" then
		return
	end
	local info = { pcall(CombatLogGetCurrentEventInfo) }
	if not info[1] then
		return
	end
	local subevent = info[3]
	if Secret(subevent) or type(subevent) ~= "string" then
		return
	end
	local sourceGUID, sourceFlags = info[5], info[7]
	local destGUID, destFlags = info[9], info[11]
	local mine = self:IsPlayerGUID(sourceGUID, sourceFlags)
	if subevent == "SWING_DAMAGE" and mine then
		-- Payload 10 is isOffHand. pcall stores ok at [1], so that value is [22].
		self:OnPlayerSwing(PlainFlag(info[22]))
	elseif subevent == "SWING_MISSED" then
		local missType = info[13]
		if mine then
			self:OnPlayerSwing(PlainFlag(info[14]))
		elseif self:IsPlayerGUID(destGUID, destFlags) and not Secret(missType) and missType == "PARRY" then
			self:OnParryHaste()
		end
	elseif subevent == "SPELL_CAST_SUCCESS" and mine then
		local spell = info[13]
		if spell == AUTO_SHOT or spell == WAND_SHOT or spell == "Auto Shot" or spell == "Shoot" then
			self:OnShotFired()
		end
	end
end
