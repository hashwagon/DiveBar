-- Player casts and channels, including crafting. Instants and pet casts are ignored.

DiveBar = DiveBar or {}

local INTERRUPT_HOLD = 0.8

local function Milliseconds(value)
	if not value then
		return nil
	end
	if value > 10000 then
		return value / 1000
	end
	return value
end

local function Closed(value)
	return issecretvalue and issecretvalue(value) and true or false
end

local function ReadInfo(reader)
	if type(reader) ~= "function" then
		return nil
	end
	local ok, a, b, c, d, e, f = pcall(reader, "player")
	if not ok or Closed(a) or not a then
		return nil
	end
	local name, text, icon, startTime, endTime
	if type(d) == "number" then
		name, text, icon, startTime, endTime = a, b, c, d, e
	elseif type(e) == "number" then
		name, text, icon, startTime, endTime = a, c, d, e, f
	else
		return nil
	end
	-- The tradeskill flag can be secret. Crafting still uses the cast bar, so leave that flag unread.
	if Closed(startTime) or Closed(endTime) then
		return nil
	end
	startTime = Milliseconds(startTime)
	endTime = Milliseconds(endTime)
	if not startTime or not endTime or endTime <= startTime then
		return nil
	end
	return {
		name = name or text or "",
		icon = icon,
		start = startTime,
		finish = endTime,
	}
end

local function ApplyCast(cast, info, mode)
	cast.mode = mode
	cast.name = info.name
	cast.icon = info.icon
	cast.start = info.start
	cast.finish = info.finish
	cast.interruptUntil = nil
end

function DiveBar:EnsureCast()
	if self.cast then
		return
	end
	self.cast = {
		mode = "idle",
		name = nil,
		icon = nil,
		start = nil,
		finish = nil,
		interruptUntil = nil,
	}
end

function DiveBar:ClearCast()
	self:EnsureCast()
	local cast = self.cast
	cast.mode = "idle"
	cast.name = nil
	cast.icon = nil
	cast.start = nil
	cast.finish = nil
	cast.interruptUntil = nil
end

function DiveBar:ShowInterrupt()
	self:EnsureCast()
	local cast = self.cast
	if cast.mode ~= "cast" and cast.mode ~= "channel" then
		return
	end
	cast.mode = "interrupt"
	cast.interruptUntil = GetTime() + INTERRUPT_HOLD
	cast.start = nil
	cast.finish = nil
end

function DiveBar:ReadActiveCast()
	self:EnsureCast()
	local info = ReadInfo(UnitCastingInfo)
	if info then
		ApplyCast(self.cast, info, "cast")
		return true
	end
	info = ReadInfo(UnitChannelInfo)
	if info then
		ApplyCast(self.cast, info, "channel")
		return true
	end
	return false
end

function DiveBar:LatencyFraction(duration)
	if not self.profile.showLatency or not duration or duration <= 0 then
		return 0
	end
	local _, _, home, world = GetNetStats()
	local ms = world or 0
	if ms <= 0 then
		ms = home or 0
	end
	local fraction = (ms / 1000) / duration
	if fraction < 0 then
		fraction = 0
	elseif fraction > 0.3 then
		fraction = 0.3
	end
	return fraction
end

function DiveBar:PollCast()
	self:EnsureCast()
	local cast = self.cast
	local now = GetTime()
	if cast.mode == "interrupt" then
		if cast.interruptUntil and now >= cast.interruptUntil then
			self:ClearCast()
			return true
		end
		return false
	end
	if cast.mode == "cast" or cast.mode == "channel" then
		if cast.finish and now > cast.finish + 0.1 then
			self:ClearCast()
			return true
		end
	end
	return false
end

function DiveBar:PreviewIcon()
	if self.previewIcon then
		return self.previewIcon
	end
	local icon
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(116)
		icon = info and (info.iconID or info.originalIconID)
	end
	if not icon and GetSpellInfo then
		local _, _, spellIcon = GetSpellInfo(116)
		icon = spellIcon
	end
	self.previewIcon = icon or "Interface\\Icons\\Spell_Frost_FrostBolt02"
	return self.previewIcon
end

-- The preview tick boxes last for the session. A bar that is turned off never previews.
DiveBar.previewShow = DiveBar.previewShow or {}

function DiveBar:PreviewShows(feature)
	return self.profile[feature] and self.previewShow[feature] ~= false
end

function DiveBar:SampleState()
	local profile = self.profile
	local swings = {}
	local progress = {}
	local showSwings = self:PreviewShows("swings")
	if showSwings and profile.swingMelee then
		swings[#swings + 1] = "melee"
		progress.melee = 0.46
	elseif showSwings and profile.swingRanged then
		swings[#swings + 1] = "shot"
		progress.shot = 0.62
	end
	local timers = {}
	local timerProgress = {}
	local timerMeta = {}
	if self:PreviewShows("timers") then
		timers[1] = "BREATH"
		timerProgress.BREATH = 0.72
		timerMeta.BREATH = { label = "Breath", value = 21.6, max = 30 }
	end
	local xp
	local xpBadge
	if self:PreviewShows("xp") then
		xp = { value = 0.44, rested = 0.26 }
		if profile.showQuestXP ~= false then
			xp.quest = 0.12
		end
		if profile.xpLevelTime ~= "off" then
			xpBadge = self.FormatLevelTime(9420, profile.xpBadgeFormat)
		end
	end
	local duration = 3
	local showCast = self:PreviewShows("cast") and true or false
	return {
		mode = showCast and "cast" or "idle",
		name = "Frostbolt",
		icon = self:PreviewIcon(),
		progress = showCast and 0.6 or 0,
		latency = self:LatencyFraction(duration),
		remain = 1.2,
		total = duration,
		showIcon = profile.showIcon,
		showName = profile.showName,
		showTime = profile.showTime,
		showLatency = profile.showLatency,
		showCast = showCast,
		swings = swings,
		progressSwing = progress,
		timers = timers,
		timerProgress = timerProgress,
		timerMeta = timerMeta,
		xp = xp,
		xpBadge = xpBadge,
	}
end

function DiveBar:BuildState()
	self:EnsureCast()
	local profile = self.profile
	local cast = self.cast
	local now = GetTime()
	local duration = 0
	local remain = 0
	local progress = 0
	if (cast.mode == "cast" or cast.mode == "channel") and cast.start and cast.finish then
		duration = cast.finish - cast.start
		remain = cast.finish - now
		if remain < 0 then
			remain = 0
		end
		if duration > 0 then
			if cast.mode == "channel" then
				progress = remain / duration
			else
				progress = (now - cast.start) / duration
			end
		end
	elseif cast.mode == "interrupt" then
		progress = 1
	end
	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end
	local equipped = self.GetVisibleSwingKeys and self:GetVisibleSwingKeys() or {}
	local consolidate = profile.consolidate ~= false
	local rangedOn = consolidate and self.RangedActive and self:RangedActive()
	if self.DisplaySwingKeys then
		equipped = self.DisplaySwingKeys(equipped, rangedOn, consolidate)
	end
	local inCombat = true
	if not profile.alwaysShow and self.InCombat then
		inCombat = self:InCombat()
	end
	local running
	if not profile.alwaysShow and self.SwingInUse then
		running = {}
		for i = 1, #equipped do
			local key = equipped[i]
			if self:SwingInUse(key) or (rangedOn and (key == "shot" or key == "wand")) then
				running[key] = true
			end
		end
	end
	local held = self.swingHold
	local swings = self.ShownSwings(profile, equipped, running, inCombat, held)
	if not profile.alwaysShow then
		self.swingHold = self.NextSwingHold(equipped, running, inCombat, held)
	else
		self.swingHold = nil
	end
	local showCast = self.ShowCastRow(profile, cast.mode)
	local progressSwing = {}
	for i = 1, #swings do
		progressSwing[swings[i]] = self:SwingProgress(swings[i])
	end
	local mirrors = self.mirrors or {}
	local showTimers = self.ShowTimerRows(profile, #mirrors)
	local timers = {}
	local timerProgress = {}
	local timerMeta = {}
	if showTimers then
		if #mirrors == 0 then
			timers[1] = "idle"
			timerProgress.idle = 0
			timerMeta.idle = { label = "", value = 0, max = 0 }
		else
			for i = 1, #mirrors do
				local mirror = mirrors[i]
				timers[#timers + 1] = mirror.name
				local fraction = 0
				if mirror.max and mirror.max > 0 and mirror.value then
					fraction = mirror.value / mirror.max
				end
				if fraction < 0 then
					fraction = 0
				elseif fraction > 1 then
					fraction = 1
				end
				timerProgress[mirror.name] = fraction
				timerMeta[mirror.name] = mirror
			end
		end
	end
	local xp
	local xpBadge
	if profile.xp and self.xp then
		xp = self.xp
		xpBadge = self:XPBadgeText()
	end
	return {
		mode = cast.mode,
		name = cast.name,
		icon = cast.icon,
		progress = progress,
		latency = cast.mode == "cast" and self:LatencyFraction(duration) or 0,
		remain = remain,
		total = duration,
		showIcon = profile.showIcon,
		showName = profile.showName,
		showTime = profile.showTime,
		showLatency = profile.showLatency,
		showCast = showCast,
		swings = swings,
		progressSwing = progressSwing,
		timers = timers,
		timerProgress = timerProgress,
		timerMeta = timerMeta,
		xp = xp,
		xpBadge = xpBadge,
	}
end

function DiveBar:LayoutKey(state)
	local parts = { state.showCast and "cast" or "nocast" }
	local timers = state.timers or {}
	for i = 1, #timers do
		parts[#parts + 1] = timers[i]
	end
	local swings = state.swings or {}
	for i = 1, #swings do
		parts[#parts + 1] = swings[i]
	end
	parts[#parts + 1] = state.xp and "xp" or "noxp"
	return table.concat(parts, "|")
end

function DiveBar:ReadCombat()
	if type(UnitAffectingCombat) ~= "function" then
		return
	end
	local ok, value = pcall(UnitAffectingCombat, "player")
	if not ok or (issecretvalue and issecretvalue(value)) then
		return
	end
	self.inCombat = value and true or false
end

function DiveBar:InCombat()
	if self.inCombat == nil then
		self:ReadCombat()
	end
	return self.inCombat and true or false
end

function DiveBar:RequestTick()
	if self.bar and self.OnUpdateFunc then
		self.bar:SetScript("OnUpdate", self.OnUpdateFunc)
	end
end

function DiveBar:NeedsTick()
	local cast = self.cast
	if cast and cast.mode ~= "idle" then
		return true
	end
	local timers = self.timers
	if not timers then
		return false
	end
	if (timers.melee.remaining or 0) > 0 or (timers.off.remaining or 0) > 0 or (timers.ranged.remaining or 0) > 0 then
		return true
	end
	if self.mirrors and #self.mirrors > 0 then
		return true
	end
	if self.Attacking and self:Attacking() then
		return true
	end
	return false
end

function DiveBar:Tick(elapsed)
	if self.AdvanceSwing then
		self:AdvanceSwing(elapsed)
	end
	local mirrorsChanged = self.PollMirrors and self:PollMirrors()
	local changed = self:ResolveCast() or self:PollCast()
	local state = self:BuildState()
	local watching = self.profile and (not self.profile.alwaysShow or self.FirstRun(self.profile))
	local folded = watching and self:LayoutKey(state) ~= self.layoutKey
	if changed or folded or mirrorsChanged then
		self:Refresh()
	elseif self.bar and self.profile then
		self:Paint(self.bar, state, self:Theme(), self.profile, self.profile.width)
	end
	if not self:NeedsTick() and self.bar then
		self.bar:SetScript("OnUpdate", nil)
	end
end

function DiveBar:RememberCast()
	local cast = self.cast
	if cast.name then
		cast.lastName = cast.name
		cast.lastIcon = cast.icon
	end
end

function DiveBar:ResolveCast()
	self:EnsureCast()
	local cast = self.cast
	local changed = false
	if cast.pendingInterrupt then
		cast.pendingInterrupt = nil
		cast.pendingStop = nil
		cast.pendingChannelStop = nil
		if cast.mode == "cast" or cast.mode == "channel" then
			self:ShowInterrupt()
			changed = true
		end
	end
	if cast.pendingStop then
		cast.pendingStop = nil
		if cast.mode == "cast" then
			-- A craft can send stop while the cast is still running. Keep the bar until it is actually gone.
			local info = ReadInfo(UnitCastingInfo)
			if info then
				ApplyCast(cast, info, "cast")
			else
				self:ClearCast()
				changed = true
			end
		end
	end
	if cast.pendingChannelStop then
		cast.pendingChannelStop = nil
		if cast.mode == "channel" then
			local info = ReadInfo(UnitChannelInfo)
			if info then
				ApplyCast(cast, info, "channel")
			else
				self:ClearCast()
				changed = true
			end
		end
	end
	return changed
end

function DiveBar:OnCastEvent(event, unit)
	if unit and unit ~= "player" then
		return
	end
	self:EnsureCast()
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
		self.cast.pendingStop = nil
		self.cast.pendingInterrupt = nil
		if self:ReadActiveCast() then
			self:RememberCast()
			self:RequestTick()
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		self.cast.pendingChannelStop = nil
		self.cast.pendingInterrupt = nil
		if self:ReadActiveCast() then
			self:RememberCast()
			self:RequestTick()
		end
	elseif event == "UNIT_SPELLCAST_STOP" then
		self.cast.pendingStop = true
		self:RequestTick()
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		self.cast.pendingChannelStop = true
		self:RequestTick()
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
		self.cast.pendingInterrupt = true
		self:RequestTick()
	end
	self:Refresh()
end

function DiveBar:OnPlayerReady()
	self.playerReady = true
	self:EnsureDB()
	self.profile, self.profileName = self:ActiveProfile()
	if not self.uiReady then
		self:CreateUI()
	end
	self:ApplySuppression()
	self:ReadGear()
	self:UpdateSpeeds()
	self:SyncAttack()
	self:ReadXP()
	self:ReadCombat()
	if self.ReadMirrors then
		self:ReadMirrors()
	end
	self:EnsureCast()
	if not self:ReadActiveCast() and self.cast.mode ~= "interrupt" then
		self:ClearCast()
	end
	self:Refresh()
	self:UpdateMinimap()
	if self:NeedsTick() then
		self:RequestTick()
	end
end

function DiveBar:RegisterCombatEvents()
	if self.combatEvents then
		return
	end
	local frame = CreateFrame("Frame")
	self.combatEvents = frame
	-- Forever's combat log is secure. Registering it, or reading the payload,
	-- is the reload dialog. PLAYER_SWING is the event this client gives
	-- instead. Era has no PLAYER_SWING, so it keeps the combat log.
	local swingEvent = self.UsesSwingEvent and self:UsesSwingEvent()
	local names = {
		"PLAYER_EQUIPMENT_CHANGED",
		"GET_ITEM_INFO_RECEIVED",
		"UNIT_ATTACK_SPEED",
		"PLAYER_ENTER_COMBAT",
		"PLAYER_LEAVE_COMBAT",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
		"START_AUTOREPEAT_SPELL",
		"STOP_AUTOREPEAT_SPELL",
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_FAILED",
		"UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_DELAYED",
		"UNIT_SPELLCAST_CHANNEL_START",
		"UNIT_SPELLCAST_CHANNEL_UPDATE",
		"UNIT_SPELLCAST_CHANNEL_STOP",
		swingEvent and "PLAYER_SWING" or "COMBAT_LOG_EVENT_UNFILTERED",
		"PLAYER_XP_UPDATE",
		"PLAYER_LEVEL_UP",
		"UPDATE_EXHAUSTION",
		"PLAYER_UPDATE_RESTING",
		"QUEST_LOG_UPDATE",
		"CHAT_MSG_COMBAT_XP_GAIN",
		"MIRROR_TIMER_START",
		"MIRROR_TIMER_PAUSE",
		"MIRROR_TIMER_STOP",
	}
	for i = 1, #names do
		frame:RegisterEvent(names[i])
	end
	frame:SetScript("OnEvent", function(_, event, ...)
		DiveBar:OnGameEvent(event, ...)
	end)
	self.OnUpdateFunc = function(_, elapsed)
		DiveBar:Tick(elapsed)
	end
end

function DiveBar:OnGameEvent(event, ...)
	if event == "PLAYER_EQUIPMENT_CHANGED" or event == "GET_ITEM_INFO_RECEIVED" then
		self:ReadGear()
		self:UpdateSpeeds()
		self:Refresh()
	elseif event == "UNIT_ATTACK_SPEED" then
		local unit = ...
		if not unit or unit == "player" then
			-- Off-hand speed is what reveals a second swing before item data arrives.
			self:ReadGear()
			self:UpdateSpeeds()
			self:Refresh()
		end
	elseif event == "PLAYER_ENTER_COMBAT" then
		self:StartMelee()
	elseif event == "PLAYER_LEAVE_COMBAT" then
		self:StopMelee()
	elseif event == "PLAYER_REGEN_DISABLED" then
		self.inCombat = true
		self:Refresh()
		-- Refresh can return early. The experience tooltip still has to drop.
		if self.SyncXPTooltip then
			self:SyncXPTooltip()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		self.inCombat = false
		if self.blizzPending then
			self:ApplySuppression()
		end
		self:Refresh()
		if self.SyncXPTooltip then
			self:SyncXPTooltip()
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		self:StartRanged()
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		self:StopRanged()
	elseif event == "PLAYER_SWING" then
		self:OnSwingEvent(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		self:OnCombatLog()
	elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or event == "UPDATE_EXHAUSTION" or event == "PLAYER_UPDATE_RESTING" or event == "QUEST_LOG_UPDATE" then
		self:ReadXP()
		self:Refresh()
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		self:OnXPGainMessage(...)
	elseif event == "MIRROR_TIMER_START" or event == "MIRROR_TIMER_PAUSE" or event == "MIRROR_TIMER_STOP" then
		if self.ReadMirrors then
			self:ReadMirrors()
		end
		self:RequestTick()
		self:Refresh()
	else
		self:OnCastEvent(event, ...)
	end
end
