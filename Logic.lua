-- Pure settings and layout rules. No WoW API calls.

DiveBar = DiveBar or {}

DiveBar.VERSION = "1.1.0"

-- Top to bottom. Timers sit under the cast bar. Experience is the anchor.
DiveBar.FEATURE_LIST = { "cast", "timers", "swings", "xp" }

DiveBar.FEATURE_LABEL = {
	timers = "Timers",
	cast = "Cast bar",
	swings = "Swing timers",
	xp = "Experience",
}

DiveBar.PADDING_KEY = {
	timers = "timerPadding",
	cast = "castPadding",
	swings = "swingPadding",
	xp = "xpPadding",
}

DiveBar.BLIZZARD_FLAG = {
	timers = "blizzTimers",
	cast = "blizzCast",
	swings = "blizzSwings",
	xp = "blizzXp",
}

local FEATURE_SET = {
	timers = true,
	cast = true,
	swings = true,
	xp = true,
}

-- Factory appearance and behavior. Lock stays off.
-- Screen anchors and intro are omitted so a new install places itself
-- and the first-run preview can still run.
-- Blizzard bars default off. Dive Bar draws its own.
DiveBar.DEFAULTS = {
	theme = "Classic",
	width = 461,
	scale = 1,
	opacity = 1,
	textSize = 10,
	lock = false,
	border = 4,
	margin = 2,
	roundedCorners = true,
	order = { "cast", "timers", "swings", "xp" },
	anchor = "xp",
	alwaysShow = false,
	cast = true,
	blizzCast = false,
	showIcon = true,
	showName = true,
	showTime = true,
	showLatency = true,
	castHeight = 16,
	castPadding = 1,
	timers = true,
	blizzTimers = false,
	timerHeight = 12,
	timerPadding = 1,
	swings = true,
	blizzSwings = false,
	swingMelee = true,
	swingRanged = true,
	swingHeight = 5,
	swingPadding = 1,
	consolidate = true,
	xp = true,
	blizzXp = false,
	showQuestXP = true,
	showXPRate = true,
	xpLevelTime = "badge",
	xpBadgeFormat = "decimal",
	xpLevelTimeSize = 7,
	xpHeight = 6,
	xpPadding = 0,
	colors = {
		melee = { 1, 0.74, 0.35 },
		off = { 0.86, 0.55, 0.26 },
		shot = { 0.427, 0.565, 0.667 },
		wand = { 0.62, 0.42, 0.78 },
	},
}

local SHOT_SUBCLASS = {
	[2] = true,  -- bow
	[3] = true,  -- gun
	[16] = true, -- thrown
	[18] = true, -- crossbow
}

-- Two-hand melee subclasses. Bows, guns, crossbows, thrown weapons, and wands are not in this set.
local TWO_HAND_SUBCLASS = {
	[1] = true,  -- two-hand axe
	[5] = true,  -- two-hand mace
	[6] = true,  -- polearm
	[8] = true,  -- two-hand sword
	[10] = true, -- staff
	[17] = true, -- spear
	[20] = true, -- fishing pole
}

local EQUIP_LOC = {
	[13] = "INVTYPE_WEAPON",
	[14] = "INVTYPE_SHIELD",
	[15] = "INVTYPE_RANGED",
	[17] = "INVTYPE_2HWEAPON",
	[21] = "INVTYPE_WEAPONMAINHAND",
	[22] = "INVTYPE_WEAPONOFFHAND",
	[23] = "INVTYPE_HOLDABLE",
	[25] = "INVTYPE_THROWN",
	[26] = "INVTYPE_RANGEDRIGHT",
}

function DiveBar.Copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, inner in pairs(value) do
		out[key] = DiveBar.Copy(inner)
	end
	return out
end

-- Older profiles stored one height, a swing band, and an experience anchor.
-- Translate those once, before defaults fill the new keys.
function DiveBar.Migrate(profile)
	if type(profile) ~= "table" then
		return
	end
	if profile.cast == nil then
		profile.cast = true
	end
	if profile.castHeight == nil and tonumber(profile.height) then
		profile.castHeight = profile.height
	end
	if profile.blizzCast == nil and profile.hideDefault ~= nil then
		profile.blizzCast = not profile.hideDefault
	end
	if profile.alwaysShow == nil and profile.idleXp ~= nil then
		profile.alwaysShow = not profile.idleXp
	end
	if profile.xpHeight == nil and profile.xpHalf == true then
		local swing = tonumber(profile.swingHeight) or DiveBar.DEFAULTS.swingHeight
		profile.xpHeight = math.max(2, swing * 0.5)
	end
	-- The old factory size was 13. One step smaller by a quarter is 10.
	if not profile.textScaled and profile.textSize == 13 then
		profile.textSize = 10
	end
	profile.textScaled = true
	if profile.xpLevelTime == nil and profile.showXPBadge == false then
		profile.xpLevelTime = "off"
	end
	profile.showXPBadge = nil
	if profile.order == nil then
		local order
		if profile.swingBand == "top" then
			order = { "swings", "cast", "timers" }
		else
			order = { "cast", "timers", "swings" }
		end
		local idle = profile.idleXp ~= false
		local position = profile.xpPosition or "below_swings"
		if idle then
			if profile.idleGrow == "down" then
				table.insert(order, 1, "xp")
			else
				order[#order + 1] = "xp"
			end
		else
			local anchor = position:find("cast", 1, true) and "cast" or "swings"
			local before = position:find("above", 1, true) and true or false
			local index
			for i = 1, #order do
				if order[i] == anchor then
					index = i
					break
				end
			end
			if not index then
				order[#order + 1] = "xp"
			elseif before then
				table.insert(order, index, "xp")
			else
				table.insert(order, index + 1, "xp")
			end
		end
		profile.order = order
	end
	if profile.anchor == nil then
		profile.anchor = profile.xp ~= false and "xp" or "cast"
	end
	if not profile.anchorMigrated then
		if profile.anchor == "xp" and profile.idleXp ~= false and profile.idleAnchorX then
			profile.anchorX = profile.idleAnchorX
			profile.anchorY = profile.idleAnchorY
			profile.anchorPoint = "center"
		end
		profile.anchorMigrated = true
	end
	-- The first swing colors were dark enough to disappear against the track.
	local function sameColor(color, r, g, b)
		if type(color) ~= "table" then
			return false
		end
		local sample = { r, g, b }
		for channel = 1, 3 do
			local value = tonumber(color[channel])
			if not value or math.abs(value - sample[channel]) > 0.001 then
				return false
			end
		end
		return true
	end
	local colors = profile.colors
	if type(colors) == "table" then
		if sameColor(colors.melee, 0.831, 0.537, 0.235) then
			colors.melee = DiveBar.Copy(DiveBar.DEFAULTS.colors.melee)
		end
		if sameColor(colors.off, 0.659, 0.408, 0.188) then
			colors.off = DiveBar.Copy(DiveBar.DEFAULTS.colors.off)
		end
	end
end

-- Fills keys that are missing. Saved values stay as they are.
function DiveBar.ApplyDefaults(profile)
	local function fill(dst, src)
		for key, value in pairs(src) do
			if dst[key] == nil then
				dst[key] = DiveBar.Copy(value)
			elseif type(value) == "table" and type(dst[key]) == "table" then
				fill(dst[key], value)
			end
		end
	end
	fill(profile, DiveBar.DEFAULTS)
end

function DiveBar.OrderedFeatures(profile)
	local order = {}
	local seen = {}
	local raw = type(profile) == "table" and profile.order or nil
	if type(raw) == "table" then
		for i = 1, #raw do
			local feature = raw[i]
			if FEATURE_SET[feature] and not seen[feature] then
				seen[feature] = true
				order[#order + 1] = feature
			end
		end
	end
	for i = 1, #DiveBar.FEATURE_LIST do
		local feature = DiveBar.FEATURE_LIST[i]
		if not seen[feature] then
			order[#order + 1] = feature
		end
	end
	return order
end

function DiveBar.NormalizeAnchor(profile)
	local order = DiveBar.OrderedFeatures(profile)
	if FEATURE_SET[profile.anchor] and profile[profile.anchor] then
		return profile.anchor
	end
	for i = 1, #order do
		if profile[order[i]] then
			return order[i]
		end
	end
	return order[1]
end

function DiveBar.MoveFeature(profile, feature, delta)
	if not FEATURE_SET[feature] or delta == 0 then
		return
	end
	local order = DiveBar.OrderedFeatures(profile)
	local index
	for i = 1, #order do
		if order[i] == feature then
			index = i
			break
		end
	end
	local destination = (index or 0) + delta
	if not index or destination < 1 or destination > #order then
		return
	end
	order[index], order[destination] = order[destination], order[index]
	profile.order = order
end

function DiveBar.Sanitize(profile)
	DiveBar.Migrate(profile)
	DiveBar.ApplyDefaults(profile)
	local defaults = DiveBar.DEFAULTS
	local function number(key, low, high)
		local value = tonumber(profile[key])
		if not value then
			profile[key] = defaults[key]
		elseif value < low then
			profile[key] = low
		elseif value > high then
			profile[key] = high
		else
			profile[key] = value
		end
	end
	number("width", 160, 1440)
	number("castHeight", 12, 48)
	number("timerHeight", 3, 40)
	number("scale", 0.5, 2)
	number("opacity", 0.15, 1)
	number("textSize", 8, 24)
	number("swingHeight", 3, 40)
	number("border", 1, 20)
	number("margin", 0, 20)
	number("xpHeight", 2, 40)
	number("xpLevelTimeSize", 4, 24)
	for _, key in pairs(DiveBar.PADDING_KEY) do
		number(key, 0, 20)
	end
	if profile.theme ~= "Forever" and profile.theme ~= "Flat" and profile.theme ~= "Classic" then
		profile.theme = defaults.theme
	end
	if profile.xpBadgeFormat ~= "decimal" and profile.xpBadgeFormat ~= "clock" then
		profile.xpBadgeFormat = defaults.xpBadgeFormat
	end
	if profile.xpLevelTime ~= "badge" and profile.xpLevelTime ~= "text" and profile.xpLevelTime ~= "off" then
		profile.xpLevelTime = defaults.xpLevelTime
	end
	local flags = {
		"lock", "showIcon", "showName", "showTime", "showLatency",
		"cast", "timers", "swings", "swingMelee", "swingRanged", "xp", "showQuestXP", "showXPRate", "consolidate", "alwaysShow",
		"blizzCast", "blizzTimers", "blizzSwings", "blizzXp", "roundedCorners",
	}
	for i = 1, #flags do
		profile[flags[i]] = profile[flags[i]] and true or false
	end
	profile.order = DiveBar.OrderedFeatures(profile)
	profile.anchor = DiveBar.NormalizeAnchor(profile)
	-- intro is "open" during the placement preview and "done" after the first lock.
	-- Leave it nil on older saves. anchorX decides those, not a missing field.
	if profile.intro ~= "open" and profile.intro ~= "done" then
		profile.intro = nil
	end
	if profile.lock and profile.intro == "open" then
		profile.intro = "done"
	end
	if type(profile.colors) ~= "table" then
		profile.colors = DiveBar.Copy(DiveBar.DEFAULTS.colors)
	end
	for key, defaults in pairs(DiveBar.DEFAULTS.colors) do
		local color = profile.colors[key]
		if type(color) ~= "table" then
			profile.colors[key] = DiveBar.Copy(defaults)
		else
			for channel = 1, 3 do
				local value = tonumber(color[channel])
				if not value then
					color[channel] = defaults[channel]
				elseif value < 0 then
					color[channel] = 0
				elseif value > 1 then
					color[channel] = 1
				else
					color[channel] = value
				end
			end
		end
	end
end

function DiveBar.CleanName(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("|", "")
	if #name > 24 then
		name = name:sub(1, 24)
	end
	name = name:gsub("%s+$", "")
	return name
end

function DiveBar.EquipLocName(equipLoc)
	if type(equipLoc) == "number" then
		return EQUIP_LOC[equipLoc]
	end
	if equipLoc == "" then
		return nil
	end
	return equipLoc
end

-- Item classes: 2 weapon, 4 armor. Shields and held items are not weapons and have no timer.
function DiveBar.ClassifyItem(classID, subclassID, equipLoc)
	classID = tonumber(classID)
	subclassID = tonumber(subclassID)
	equipLoc = DiveBar.EquipLocName(equipLoc)
	if classID ~= 2 then
		return "none"
	end
	if subclassID == 19 then
		return "wand"
	end
	if SHOT_SUBCLASS[subclassID] then
		return "shot"
	end
	if equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_SHIELD" then
		return "none"
	end
	-- One-hand and two-hand melee, including fishing poles, share the melee kind.
	-- RowsFromGear drops the off-hand row when IsTwoHanded is true.
	return "melee"
end

function DiveBar.IsTwoHanded(classID, subclassID, equipLoc)
	classID = tonumber(classID)
	subclassID = tonumber(subclassID)
	equipLoc = DiveBar.EquipLocName(equipLoc)
	if classID ~= 2 then
		return false
	end
	if subclassID == 19 or SHOT_SUBCLASS[subclassID] then
		return false
	end
	if equipLoc == "INVTYPE_2HWEAPON" then
		return true
	end
	return TWO_HAND_SUBCLASS[subclassID] and true or false
end

-- mainKind "unarmed" is an empty main hand. It still gets the one melee row.
-- twoHand is one melee swing: no off-hand row. A bow, gun, or wand stays its own row.
function DiveBar.RowsFromGear(mainKind, offKind, rangedKind, twoHand)
	local rows = {}
	if mainKind == "melee" or mainKind == "unarmed" then
		rows[#rows + 1] = "melee"
	elseif mainKind == "shot" then
		rows[#rows + 1] = "shot"
	elseif mainKind == "wand" then
		rows[#rows + 1] = "wand"
	end
	if not twoHand and offKind == "melee" then
		rows[#rows + 1] = "off"
	end
	if rangedKind == "shot" and mainKind ~= "shot" then
		rows[#rows + 1] = "shot"
	end
	if rangedKind == "wand" and mainKind ~= "wand" and offKind ~= "wand" then
		rows[#rows + 1] = "wand"
	end
	return rows
end

-- While consolidated, a bow takes the melee rows' place. Separate mode keeps every row.
function DiveBar.DisplaySwingKeys(equipped, rangedActive, consolidate)
	if consolidate == false then
		return equipped or {}
	end
	local melee, ranged = {}, {}
	for i = 1, #(equipped or {}) do
		local key = equipped[i]
		if key == "shot" or key == "wand" then
			ranged[#ranged + 1] = key
		else
			melee[#melee + 1] = key
		end
	end
	if rangedActive and #ranged > 0 then
		return ranged
	end
	if #melee > 0 then
		return melee
	end
	return ranged
end

function DiveBar.VisibleRows(profile, equipped)
	if not profile.swings then
		return {}
	end
	local rows = {}
	for i = 1, #(equipped or {}) do
		local key = equipped[i]
		local melee = key == "melee" or key == "off"
		local ranged = key == "shot" or key == "wand"
		if melee and profile.swingMelee then
			rows[#rows + 1] = key
		elseif ranged and profile.swingRanged then
			rows[#rows + 1] = key
		end
	end
	return rows
end

-- A new bar has no anchor and has never been locked. The preview stays up
-- after the anchor is saved, until the first lock. An older bar that already
-- has anchorX is not a first run just because intro is missing.
function DiveBar.FirstRun(profile)
	if type(profile) ~= "table" then
		return false
	end
	if profile.lock or profile.intro == "done" then
		return false
	end
	if profile.intro == "open" then
		return true
	end
	if profile.anchorX ~= nil then
		return false
	end
	return true
end

function DiveBar.OpenIntro(profile)
	if DiveBar.FirstRun(profile) then
		profile.intro = "open"
	end
end

-- The first lock ends the preview. After that, Always show bars decides what stays up.
-- A later unlock only clears lock.
function DiveBar.SetLockState(profile, locked)
	locked = locked and true or false
	profile.lock = locked
	if locked then
		profile.intro = "done"
	end
end

function DiveBar.ShowAll(profile)
	return DiveBar.FirstRun(profile) or profile.alwaysShow
end

-- A swing row appears when that swing starts. It stays through the rest of
-- combat, including the empty reset between swings. After combat it stays
-- only until the current swing resets, then it drops.
-- Always show, and the placement preview, keep every equipped row up.
function DiveBar.ShownSwings(profile, equipped, running, inCombat, held)
	local rows = DiveBar.VisibleRows(profile, equipped)
	if DiveBar.ShowAll(profile) then
		return rows
	end
	local shown = {}
	for i = 1, #rows do
		local key = rows[i]
		local active = running and running[key]
		local kept = held and held[key]
		if active or (inCombat and kept) then
			shown[#shown + 1] = key
		end
	end
	return shown
end

function DiveBar.NextSwingHold(equipped, running, inCombat, held)
	local allowed = {}
	for i = 1, #(equipped or {}) do
		allowed[equipped[i]] = true
	end
	local nextHold = {}
	for i = 1, #(equipped or {}) do
		local key = equipped[i]
		if allowed[key] then
			local active = running and running[key]
			local kept = held and held[key]
			if active or (inCombat and kept) then
				nextHold[key] = true
			end
		end
	end
	return nextHold
end

function DiveBar.ShowCastRow(profile, mode)
	if not profile.cast then
		return false
	end
	if DiveBar.ShowAll(profile) then
		return true
	end
	-- Crafting, fishing, mounts, and other casts stay visible out of combat.
	return mode == "cast" or mode == "channel" or mode == "interrupt"
end

function DiveBar.ShowTimerRows(profile, count)
	if not profile.timers then
		return false
	end
	if DiveBar.ShowAll(profile) then
		return true
	end
	return (count or 0) > 0
end

function DiveBar.FeaturePadding(profile, feature)
	local value = tonumber(profile[DiveBar.PADDING_KEY[feature]]) or 0
	if value < 0 then
		value = 0
	end
	return value
end

-- spec.cast, spec.xp, spec.swings, spec.timers. Order is top to bottom.
-- barH is the trough. h adds that bar's padding above and below it.
function DiveBar.Blocks(profile, spec)
	spec = spec or {}
	local order = DiveBar.OrderedFeatures(profile)
	local blocks = {}
	local function add(block, barH)
		local pad = DiveBar.FeaturePadding(profile, block.feature)
		block.pad = pad
		block.barH = barH
		block.h = barH + pad * 2
		blocks[#blocks + 1] = block
	end
	for i = 1, #order do
		local feature = order[i]
		if feature == "swings" and spec.swings and #spec.swings > 0 then
			for s = 1, #spec.swings do
				add({ feature = "swings", kind = "swing", key = spec.swings[s] }, profile.swingHeight)
			end
		elseif feature == "timers" and spec.timers and #spec.timers > 0 then
			for s = 1, #spec.timers do
				add({ feature = "timers", kind = "timer", key = spec.timers[s], slot = s }, profile.timerHeight)
			end
		elseif feature == "xp" and spec.xp then
			add({ feature = "xp", kind = "xp" }, profile.xpHeight)
		elseif feature == "cast" and spec.cast then
			add({ feature = "cast", kind = "cast" }, profile.castHeight)
		end
	end
	return blocks
end

function DiveBar.ContentHeight(blocks)
	local height = 0
	for i = 1, #blocks do
		height = height + blocks[i].h
	end
	return height
end

-- "center" is the anchor group. "top" is the first row below a hidden anchor.
-- "bottom" is the last row above it. The measured point is the anchor slot.
function DiveBar.AnchorMeasure(blocks, order, anchor)
	local rank = {}
	for i = 1, #order do
		rank[order[i]] = i
	end
	local anchorRank = rank[anchor] or 1
	local centerIndex
	local lastAbove
	local firstBelow
	for i = 1, #blocks do
		local feature = blocks[i].feature
		if feature == anchor then
			if not centerIndex then
				centerIndex = i
			end
		elseif (rank[feature] or 0) < anchorRank then
			lastAbove = i
		elseif not firstBelow and (rank[feature] or 0) > anchorRank then
			firstBelow = i
		end
	end
	if centerIndex then
		return "center", centerIndex
	end
	if firstBelow then
		return "top", firstBelow
	end
	if lastAbove then
		return "bottom", lastAbove
	end
	return nil
end

-- UI-Tooltip-Border slices are 16 texels. The silver line is the outer 6.
-- That is the piece the slider scales. The other 10 texels are empty.
-- The inner part of the 6 is the start of the rounded corner, so it is clear.
-- Rows start this far through that piece. A rounded corner is clear outside
-- its curve, so rows tuck in to 5 of the 6 texels there, as Blizzard's tooltip insets do.
-- The outer BORDER_SHADOW of the line is soft shadow; the silver starts after it.
DiveBar.BORDER_LINE = 6 / 16
DiveBar.BORDER_INSET = 0.4
DiveBar.BORDER_INSET_ROUNDED = 5 / 6
DiveBar.BORDER_SHADOW = 0.6

function DiveBar.BorderThickness(edge)
	local thickness = (tonumber(edge) or 0) * DiveBar.BORDER_LINE
	if thickness < 2 then
		thickness = 2
	end
	return thickness
end

function DiveBar.ContentInset(line, rounded)
	local share = rounded and DiveBar.BORDER_INSET_ROUNDED or DiveBar.BORDER_INSET
	local inset = (tonumber(line) or 0) * share
	if inset < 1 then
		inset = 1
	end
	if line and inset > line then
		inset = line
	end
	return inset
end

-- The drawn corner stays the full line, so the curve can cover the bars.
-- The frame only reserves the smaller inset, and the border overlaps the rest.
function DiveBar.FitChrome(contentH, edge, rim, rounded)
	if not contentH or contentH < 0 then
		contentH = 0
	end
	local line = rim
	if not line or line < 1 then
		line = DiveBar.BorderThickness(edge)
	end
	local inset = DiveBar.ContentInset(line, rounded)
	local frameH = contentH + inset * 2
	if frameH < 1 then
		frameH = 1
	end
	return line, inset, frameH
end

-- Standard experience-bar colors: current XP blue, rested purple, completed quests yellow.
DiveBar.XP_COLOR = { 0.0, 0.39, 0.88 }
DiveBar.RESTED_COLOR = { 0.58, 0.0, 0.55 }
DiveBar.QUEST_COLOR = { 1, 0.82, 0 }
DiveBar.XP_COLOR_TOP = { 0.55, 0.78, 1.0 }
DiveBar.RESTED_COLOR_TOP = { 0.82, 0.45, 0.86 }
DiveBar.QUEST_COLOR_TOP = { 1, 0.95, 0.55 }

function DiveBar.XPRoom(current)
	local value = tonumber(current) or 0
	if value < 0 then
		value = 0
	elseif value > 1 then
		value = 1
	end
	return 1 - value
end

-- How much of an extension past current XP still fits on this bar.
function DiveBar.XPSegment(current, extra)
	local room = DiveBar.XPRoom(current)
	local amount = tonumber(extra) or 0
	if amount < 0 then
		amount = 0
	end
	if amount > room then
		amount = room
	end
	return amount
end

-- Rested and completed-quest XP both start where current XP ends.
-- The shorter one is drawn above the other. Equal lengths put quest above.
function DiveBar.XPOverlayTop(rested, quest)
	local rest = tonumber(rested) or 0
	local questXP = tonumber(quest) or 0
	if rest < 0 then
		rest = 0
	end
	if questXP < 0 then
		questXP = 0
	end
	if questXP <= rest then
		return "quest"
	end
	return "rested"
end
