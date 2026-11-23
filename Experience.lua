-- Experience uses the standard blue bar and the purple rested extension.
-- Completed quests add a yellow extension from the same point. The shorter
-- of rested and quest XP is drawn above the other. The quest total is the
-- reward the log reports, which can differ a little from the turn-in.
-- Hovering that row shows a classic experience tooltip. Secret numbers are left off the line.
-- Below it are session figures: XP per hour, time to level and kills to level. They reset on reload or /divebar xpreset.
-- The tooltip stays hidden while the player is in combat.

DiveBar = DiveBar or {}

local GOLD = { 1, 0.824, 0 }
local WHITE = { 1, 1, 1 }
local RESTING = { 0.1, 1, 0.1 }
local QUEST = { 1, 0.82, 0 }

local function Secret(value)
	return issecretvalue and issecretvalue(value) and true or false
end

local function ReadNumber(func, ...)
	if type(func) ~= "function" then
		return nil, false
	end
	local ok, value = pcall(func, ...)
	if not ok then
		return nil, false
	end
	if Secret(value) then
		return nil, true
	end
	if type(value) ~= "number" then
		return nil, false
	end
	return value, false
end

local function FormatNumber(value)
	local rounded = math.floor(value + 0.5)
	if rounded < 0 then
		rounded = 0
	end
	if type(BreakUpLargeNumbers) == "function" then
		local ok, text = pcall(BreakUpLargeNumbers, rounded)
		if ok and type(text) == "string" then
			return text
		end
	end
	local digits = tostring(rounded)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return grouped
end

local function FormatPercent(current, maxXP)
	local value = 0
	if maxXP > 0 then
		value = current * 100 / maxXP
	end
	if value < 0 then
		value = 0
	elseif value > 100 then
		value = 100
	end
	local tenths = math.floor(value * 10 + 0.5)
	if tenths % 10 == 0 then
		return string.format("%d%%", math.floor(tenths / 10))
	end
	return string.format("%d.%d%%", math.floor(tenths / 10), tenths % 10)
end

local function FormatDuration(seconds)
	seconds = math.floor(seconds)
	if seconds < 60 then
		return "<1m"
	end
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds % 86400 / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	if days > 0 then
		return string.format("%dd %dh", days, hours)
	end
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

local function Line(text, color)
	return { text = text, r = color[1], g = color[2], b = color[3] }
end

-- Session tracking follows Titan XP: gains are summed across level-ups from the
-- first reading after login or reload, and kill XP comes from the combat XP message.
-- Kills to level uses the average of recent kills, so one elite does not swing it.
local RECENT_KILLS = 10
local RATE_MIN_SECONDS = 60

function DiveBar.StepXPSession(state, level, current, maxXP, now)
	if state.start == nil then
		state.start = now
		state.gained = 0
		state.level = level
		state.current = current
		state.maxXP = maxXP
		return 0
	end
	local gain
	local leveled = level ~= nil and state.level ~= nil and level > state.level
	if current < state.current or leveled then
		local left = state.maxXP - state.current
		if left < 0 then
			left = 0
		end
		gain = left + current
		-- The XP can reset before UnitLevel catches up. Count the level now so the later reading does not count it again.
		if not leveled and state.level ~= nil then
			level = state.level + 1
		end
	else
		gain = current - state.current
	end
	state.gained = state.gained + gain
	if level ~= nil and (state.level == nil or level > state.level) then
		state.level = level
	end
	state.current = current
	state.maxXP = maxXP
	return gain
end

function DiveBar.AddKillXP(state, xp)
	if type(xp) ~= "number" or xp <= 0 then
		return
	end
	local kills = state.kills
	if type(kills) ~= "table" then
		kills = {}
		state.kills = kills
	end
	kills[#kills + 1] = xp
	while #kills > RECENT_KILLS do
		table.remove(kills, 1)
	end
	state.lastKill = xp
end

function DiveBar.XPSessionSummary(state, now, remain)
	if not state or state.start == nil or type(now) ~= "number" then
		return nil
	end
	local elapsed = now - state.start
	if elapsed < 0 then
		elapsed = 0
	end
	local summary = {
		elapsed = elapsed,
		gained = state.gained or 0,
	}
	-- The first minute counts as a full minute, so an early kill does not read as a huge rate.
	summary.rate = summary.gained * 3600 / math.max(elapsed, RATE_MIN_SECONDS)
	if summary.rate > 0 and remain ~= nil and remain > 0 then
		summary.toLevel = remain * 3600 / summary.rate
	end
	local kills = state.kills
	if type(kills) == "table" and #kills > 0 then
		local total = 0
		for i = 1, #kills do
			total = total + kills[i]
		end
		summary.lastKill = state.lastKill
		summary.averageKill = total / #kills
		if remain ~= nil and remain > 0 then
			summary.killsToLevel = math.ceil(remain / summary.averageKill)
		end
	end
	return summary
end

-- Shown until the session earns experience. Fonts without the glyph get NO_RATE_FALLBACK.
DiveBar.NO_RATE_TEXT = "\226\136\158"
DiveBar.NO_RATE_FALLBACK = "--"
-- The infinity glyph only fills the lower-case height, so it is drawn larger to match the digits.
DiveBar.NO_RATE_SCALE = 1.4

-- "decimal" is 37m, 2.6h, 14h, 1.3d. "clock" is 37m, 2h 37m, 1d 4h.
function DiveBar.FormatLevelTime(seconds, style)
	if type(seconds) ~= "number" or seconds ~= seconds or seconds < 0 then
		return nil
	end
	local minutes = math.max(1, math.floor(seconds / 60 + 0.5))
	if minutes < 60 then
		return string.format("%dm", minutes)
	end
	if style == "clock" then
		if minutes < 1440 then
			return string.format("%dh %dm", math.floor(minutes / 60), minutes % 60)
		end
		return string.format("%dd %dh", math.floor(minutes / 1440), math.floor(minutes % 1440 / 60))
	end
	local tenths = math.floor(seconds / 360 + 0.5)
	if tenths < 100 then
		return string.format("%d.%dh", math.floor(tenths / 10), tenths % 10)
	end
	local hours = math.floor(seconds / 3600 + 0.5)
	if hours < 24 then
		return string.format("%dh", hours)
	end
	local dayTenths = math.floor(seconds / 8640 + 0.5)
	if dayTenths < 100 then
		return string.format("%d.%dd", math.floor(dayTenths / 10), dayTenths % 10)
	end
	return string.format("%dd", math.floor(seconds / 86400 + 0.5))
end

-- The badge covers the whole experience strip: the bar, its padding, and the frame
-- edge it touches. Its rim is the frame's line, thinned so a short strip keeps room for the number.
-- Under 9 px there is no room at all.
function DiveBar.XPBadgeSize(stripH, size, frameLine)
	stripH = tonumber(stripH) or 0
	if stripH < 9 then
		return nil
	end
	local rim = math.min(tonumber(frameLine) or 2, stripH * 0.25)
	if rim < 2 then
		rim = 2
	end
	local font = math.min(tonumber(size) or 10, stripH - 4)
	if font < 4 then
		font = 4
	end
	return font, rim, math.max(rim + 2, math.floor(font * 0.5 + 0.5))
end

-- The right edge sits on the end of the blue fill. When the fill is narrower
-- than the chip, the chip starts at that end instead, so its edge still marks the XP.
-- shadow is the clear outer band of the chip's rim; the visible edge is inside it.
function DiveBar.XPBadgeOffset(filled, chipW, troughW, shadow)
	shadow = shadow or 0
	local x = filled - chipW + shadow
	if x + shadow < 0 then
		x = filled - shadow
	end
	if x + chipW - shadow > troughW then
		x = troughW - chipW + shadow
	end
	if x + shadow < 0 then
		x = -shadow
	end
	return x
end

function DiveBar:XPBadgeText()
	local profile = self.profile
	local session = self.xpSession
	if not profile or profile.xpLevelTime == "off" or type(session) ~= "table" then
		return nil
	end
	if type(session.current) ~= "number" or type(session.maxXP) ~= "number" or type(GetTime) ~= "function" then
		return nil
	end
	local summary = self.XPSessionSummary(session, GetTime(), session.maxXP - session.current)
	if not summary then
		return nil
	end
	if not summary.toLevel then
		return self.NO_RATE_TEXT
	end
	return self.FormatLevelTime(summary.toLevel, profile.xpBadgeFormat)
end

-- Time to level moves with the clock as well as with XP, so check it now and then.
function DiveBar:WatchXPBadge()
	if self.xpBadgeTicker or not C_Timer or type(C_Timer.NewTicker) ~= "function" then
		return
	end
	self.xpBadgeTicker = C_Timer.NewTicker(10, function()
		local bar = DiveBar.bar
		if not bar or not bar.xp or not bar.xp:IsShown() then
			return
		end
		if DiveBar:XPBadgeText() ~= bar.xp.badgeText then
			DiveBar:Refresh()
		end
	end)
end

-- Turns a format string like "%s dies, you gain %d experience." into a pattern,
-- and remembers which capture holds the number. Positional specs like %1$d are allowed.
function DiveBar.KillXPPattern(template)
	if type(template) ~= "string" or template == "" then
		return nil
	end
	local order = 0
	local numberCapture
	local marked = template:gsub("%%(%d*%$?)([sd])", function(_, kind)
		order = order + 1
		if kind == "d" then
			numberCapture = numberCapture or order
			return "\002"
		end
		return "\001"
	end)
	if not numberCapture then
		return nil
	end
	local pattern = marked:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	pattern = pattern:gsub("\001", "(.-)"):gsub("\002", "(%%d+)")
	return "^" .. pattern, numberCapture
end

function DiveBar.ParseKillXP(message, pattern, numberCapture)
	if type(message) ~= "string" or not pattern then
		return nil
	end
	local captures = { message:match(pattern) }
	return tonumber(captures[numberCapture])
end

function DiveBar.XPTooltipLines(info)
	local lines = {}
	if info.level ~= nil then
		lines[#lines + 1] = Line(string.format("Level %d Experience", math.floor(info.level)), GOLD)
	end
	local current = info.current
	local maxXP = info.maxXP
	if current ~= nil and current < 0 then
		current = 0
	end
	if current ~= nil and maxXP ~= nil and maxXP > 0 then
		lines[#lines + 1] = Line(string.format(
			"%s / %s (%s)",
			FormatNumber(current),
			FormatNumber(maxXP),
			FormatPercent(current, maxXP)
		), WHITE)
		local remain = maxXP - current
		if remain < 0 then
			remain = 0
		end
		lines[#lines + 1] = Line(string.format("%s XP remaining", FormatNumber(remain)), WHITE)
	end
	local restedKnown = info.restedKnown and true or false
	local rested = info.rested
	if restedKnown and rested ~= nil and rested > 0 then
		lines[#lines + 1] = Line(string.format("Rested XP: %s", FormatNumber(rested)), WHITE)
	end
	if info.quest ~= nil and info.quest > 0 then
		local head = "Quests ready"
		local ready = tonumber(info.questCount)
		if ready and ready > 0 then
			ready = math.floor(ready)
			head = ready == 1 and "1 quest ready" or string.format("%d quests ready", ready)
		end
		local share
		if maxXP ~= nil and maxXP > 0 and info.quest < maxXP then
			share = FormatPercent(info.quest, maxXP)
		end
		local summary = string.format("%s: ~%s XP", head, FormatNumber(info.quest))
		if share then
			summary = string.format("%s (%s)", summary, share)
		end
		lines[#lines + 1] = Line(summary, QUEST)
		if current ~= nil and maxXP ~= nil and maxXP > 0 then
			local after = current + info.quest
			if after >= maxXP then
				local over = after - maxXP
				if over > 0 then
					lines[#lines + 1] = Line(string.format("After turn-in: level up (~%s XP over)", FormatNumber(over)), QUEST)
				else
					lines[#lines + 1] = Line("After turn-in: level up", QUEST)
				end
			else
				lines[#lines + 1] = Line(string.format(
					"After turn-in: %s / %s (%s)",
					FormatNumber(after),
					FormatNumber(maxXP),
					FormatPercent(after, maxXP)
				), QUEST)
			end
		end
	end
	if info.resting then
		lines[#lines + 1] = Line("Resting", RESTING)
	end
	local session = info.session
	if session then
		lines[#lines + 1] = Line(" ", WHITE)
		lines[#lines + 1] = Line(string.format(
			"This session: %s XP in %s",
			FormatNumber(session.gained),
			FormatDuration(session.elapsed)
		), WHITE)
		if session.rate then
			lines[#lines + 1] = Line(string.format("XP per hour: %s", FormatNumber(session.rate)), WHITE)
		end
		if session.toLevel then
			lines[#lines + 1] = Line(string.format("Time to level: %s", FormatDuration(session.toLevel)), WHITE)
		end
		if session.lastKill then
			lines[#lines + 1] = Line(string.format("Last kill: %s XP", FormatNumber(session.lastKill)), WHITE)
		end
		if session.killsToLevel then
			lines[#lines + 1] = Line(string.format(
				"Kills to level: ~%s (%s XP average)",
				FormatNumber(session.killsToLevel),
				FormatNumber(session.averageKill)
			), WHITE)
		end
	end
	return lines
end

function DiveBar:XPTooltipInfo()
	local info = {
		resting = false,
		restedKnown = false,
	}
	local level, levelSecret = ReadNumber(UnitLevel, "player")
	if not levelSecret and level ~= nil then
		info.level = level
	end
	local current, currentSecret = ReadNumber(UnitXP, "player")
	if not currentSecret and current ~= nil then
		info.current = current
	end
	local maxXP, maxSecret = ReadNumber(UnitXPMax, "player")
	if not maxSecret and maxXP ~= nil then
		info.maxXP = maxXP
	end
	if type(GetXPExhaustion) == "function" then
		local rested, restedSecret = ReadNumber(GetXPExhaustion)
		if not restedSecret then
			info.restedKnown = true
			info.rested = rested or 0
		end
	end
	if type(IsResting) == "function" then
		local ok, value = pcall(IsResting)
		if ok and not Secret(value) and (value == true or value == 1) then
			info.resting = true
		end
	end
	local showQuest = not self.profile or self.profile.showQuestXP ~= false
	if showQuest and self.questXPKnown and type(self.questXP) == "number" and self.questXP > 0 then
		info.quest = self.questXP
		if type(self.questCount) == "number" and self.questCount > 0 then
			info.questCount = self.questCount
		end
	end
	local showRate = not self.profile or self.profile.showXPRate ~= false
	local cap, capSecret = ReadNumber(GetMaxPlayerLevel)
	local capped = not capSecret and cap ~= nil and info.level ~= nil and info.level >= cap
	if showRate and not capped then
		local remain
		if info.current ~= nil and info.maxXP ~= nil and info.maxXP > 0 then
			remain = info.maxXP - info.current
		end
		if self.xpSession and type(GetTime) == "function" then
			info.session = self.XPSessionSummary(self.xpSession, GetTime(), remain)
		end
		info.session = info.session or { elapsed = 0, gained = 0, rate = 0 }
	end
	return info
end

function DiveBar:TrackXPSession(level, current, maxXP)
	if type(GetTime) ~= "function" then
		return
	end
	if type(self.xpSession) ~= "table" then
		self.xpSession = {}
	end
	self.StepXPSession(self.xpSession, level, current, maxXP, GetTime())
	self:WatchXPBadge()
end

function DiveBar:ResetXPSession()
	self.xpSession = nil
	self:ReadXP()
end

function DiveBar:OnXPGainMessage(message)
	if Secret(message) or type(message) ~= "string" then
		return
	end
	if self.killXPPattern == nil then
		local pattern, capture = self.KillXPPattern(COMBATLOG_XPGAIN_FIRSTPERSON)
		self.killXPPattern = pattern or false
		self.killXPCapture = capture
	end
	local xp = self.ParseKillXP(message, self.killXPPattern or nil, self.killXPCapture)
	if not xp then
		return
	end
	if type(self.xpSession) ~= "table" then
		self.xpSession = {}
	end
	self.AddKillXP(self.xpSession, xp)
	self:RefreshXPTooltip()
end

local function RewardXP(questID)
	if type(GetQuestLogRewardXP) ~= "function" then
		return nil, false
	end
	local ok, xp
	if questID then
		ok, xp = pcall(GetQuestLogRewardXP, questID)
	else
		ok, xp = pcall(GetQuestLogRewardXP)
	end
	if not ok then
		return nil, false
	end
	if Secret(xp) then
		return nil, true
	end
	if type(xp) ~= "number" then
		return nil, false
	end
	return xp, false
end

local function NumQuestEntries()
	local modern
	local classic
	if C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries) == "function" then
		local ok, count = pcall(C_QuestLog.GetNumQuestLogEntries)
		if ok and type(count) == "number" and not Secret(count) and count >= 0 then
			modern = count
		end
	end
	if type(GetNumQuestLogEntries) == "function" then
		local ok, count = pcall(GetNumQuestLogEntries)
		if ok and type(count) == "number" and not Secret(count) and count >= 0 then
			classic = count
		end
	end
	if modern and classic then
		return math.max(modern, classic)
	end
	return modern or classic or 0
end

local function On(value)
	return value == true or value == 1
end

local function QuestEntry(index)
	if C_QuestLog and type(C_QuestLog.GetInfo) == "function" then
		local ok, info = pcall(C_QuestLog.GetInfo, index)
		if ok and type(info) == "table" then
			return {
				isHeader = info.isHeader,
				isHidden = info.isHidden,
				isComplete = info.isComplete,
				questID = info.questID,
				logIndex = info.questLogIndex or index,
			}
		end
	end
	if type(GetQuestLogTitle) ~= "function" then
		return nil
	end
	local ok, title, _, _, isHeader, _, isComplete, _, questID = pcall(GetQuestLogTitle, index)
	if not ok or Secret(title) then
		return nil
	end
	return {
		isHeader = isHeader,
		isComplete = isComplete,
		questID = questID,
		logIndex = index,
	}
end

-- ReadyForTurnIn is the modern check. Older logs use isComplete == 1.
local function ReadyToTurnIn(info)
	local questID = info.questID
	if Secret(questID) or type(questID) ~= "number" or questID <= 0 then
		return false
	end
	if C_QuestLog and type(C_QuestLog.ReadyForTurnIn) == "function" then
		local ok, ready = pcall(C_QuestLog.ReadyForTurnIn, questID)
		if ok and not Secret(ready) then
			return ready == true or ready == 1
		end
	end
	if type(IsQuestComplete) == "function" then
		local ok, done = pcall(IsQuestComplete, questID)
		if ok and not Secret(done) and (done == true or done == 1) then
			return true
		end
	end
	local flag = info.isComplete
	if Secret(flag) then
		return false
	end
	return flag == 1 or flag == true
end

local function ScanQuests()
	local total = 0
	local quests = 0
	local known = true
	local pending = {}
	local count = NumQuestEntries()
	for index = 1, count do
		local info = QuestEntry(index)
		if info and not Secret(info.isHeader) and not On(info.isHeader) and not Secret(info.isHidden) and not On(info.isHidden) then
			if Secret(info.questID) then
				known = false
			elseif ReadyToTurnIn(info) then
				local xp, secret = RewardXP(info.questID)
				if secret then
					known = false
				elseif type(xp) == "number" and xp > 0 then
					total = total + xp
					quests = quests + 1
				else
					pending[#pending + 1] = info
				end
			end
		end
	end
	-- Some clients only report the selected quest. Ask those, then put the selection back.
	if #pending > 0 and type(SelectQuestLogEntry) == "function" then
		local previous
		if type(GetQuestLogSelection) == "function" then
			local ok, selected = pcall(GetQuestLogSelection)
			if ok and type(selected) == "number" and not Secret(selected) then
				previous = selected
			end
		end
		for i = 1, #pending do
			local info = pending[i]
			local index = info.logIndex
			if type(index) == "number" then
				pcall(SelectQuestLogEntry, index)
				local xp, secret = RewardXP(info.questID)
				if secret then
					known = false
				elseif not xp or xp <= 0 then
					local plain, plainSecret = RewardXP(nil)
					if plainSecret then
						known = false
					elseif type(plain) == "number" and plain > 0 then
						total = total + plain
						quests = quests + 1
					end
				elseif xp > 0 then
					total = total + xp
					quests = quests + 1
				end
			end
		end
		if previous and previous > 0 then
			pcall(SelectQuestLogEntry, previous)
		end
	end
	return total, known, quests
end

function DiveBar:CompletedQuestXP()
	if self.scanningQuests then
		return self.questXP or 0, self.questXPKnown and true or false
	end
	self.scanningQuests = true
	local ok, total, known, quests = pcall(ScanQuests)
	self.scanningQuests = false
	if not ok or not known then
		return self.questXP or 0, self.questXPKnown and true or false
	end
	if type(total) ~= "number" or total < 0 then
		total = 0
	end
	if type(quests) ~= "number" or quests < 0 then
		quests = 0
	end
	self.questXP = total
	self.questCount = quests
	self.questXPKnown = true
	return total, true
end

function DiveBar:ReadXP()
	local maxXP, maxSecret = ReadNumber(UnitXPMax, "player")
	local current, currentSecret = ReadNumber(UnitXP, "player")
	if maxSecret or currentSecret then
		self:RefreshXPTooltip()
		return
	end
	if not maxXP or maxXP <= 0 then
		self.xp = nil
		self:RefreshXPTooltip()
		return
	end
	local level, levelSecret = ReadNumber(UnitLevel, "player")
	local cap, capSecret = ReadNumber(GetMaxPlayerLevel)
	if not levelSecret and not capSecret and level and cap and level >= cap then
		self.xp = nil
		self:RefreshXPTooltip()
		return
	end
	if not current then
		current = 0
	end
	self:TrackXPSession(not levelSecret and level or nil, current, maxXP)
	local rested, restedSecret = ReadNumber(GetXPExhaustion)
	local value = current / maxXP
	if value < 0 then
		value = 0
	elseif value > 1 then
		value = 1
	end
	local restedFraction
	if restedSecret then
		restedFraction = self.xp and self.xp.rested or 0
	else
		if not rested or rested < 0 then
			rested = 0
		end
		restedFraction = rested / maxXP
		if restedFraction < 0 then
			restedFraction = 0
		end
	end
	local showQuest = not self.profile or self.profile.showQuestXP ~= false
	local questAmount, questKnown = 0, false
	if showQuest and self.CompletedQuestXP then
		questAmount, questKnown = self:CompletedQuestXP()
	end
	local questFraction = 0
	if showQuest and questKnown and type(questAmount) == "number" and maxXP > 0 then
		if questAmount < 0 then
			questAmount = 0
		end
		questFraction = questAmount / maxXP
		if questFraction < 0 then
			questFraction = 0
		end
	elseif showQuest and self.xp and self.xp.quest then
		questFraction = self.xp.quest
	end
	self.xp = {
		value = value,
		rested = restedFraction,
		quest = questFraction,
	}
	self:RefreshXPTooltip()
end

function DiveBar:TooltipOwned(row)
	if not GameTooltip or not row then
		return false
	end
	if GameTooltip.IsOwned then
		return GameTooltip:IsOwned(row) and true or false
	end
	if GameTooltip.GetOwner then
		return GameTooltip:GetOwner() == row
	end
	return false
end

function DiveBar:CursorOver(region)
	if not region or not region.IsShown or not region:IsShown() then
		return false
	end
	if region.IsMouseOver then
		return region:IsMouseOver() and true or false
	end
	if type(MouseIsOver) == "function" then
		return MouseIsOver(region) and true or false
	end
	return false
end

function DiveBar.XPTooltipLowerHalf(centerY, scale, uiScale, height)
	if not centerY or not scale or not uiScale or not height or uiScale <= 0 or height <= 0 then
		return true
	end
	return (centerY * scale) < (height * uiScale * 0.5)
end

function DiveBar:AnchorXPTooltip(row)
	local host = row.tipHost or row
	local centerY
	local scale
	local uiScale
	local height
	if host.GetCenter then
		centerY = select(2, host:GetCenter())
	end
	if host.GetEffectiveScale then
		scale = host:GetEffectiveScale()
	end
	if UIParent and UIParent.GetHeight and UIParent.GetEffectiveScale then
		height = UIParent:GetHeight()
		uiScale = UIParent:GetEffectiveScale()
	end
	local lower = self.XPTooltipLowerHalf(centerY, scale, uiScale, height)
	GameTooltip:ClearAllPoints()
	if lower then
		GameTooltip:SetPoint("BOTTOM", row, "TOP", 0, 2)
	else
		GameTooltip:SetPoint("TOP", row, "BOTTOM", 0, -2)
	end
end

function DiveBar:HideXPTooltip(row)
	if self:TooltipOwned(row) then
		GameTooltip:Hide()
	end
end

function DiveBar:ShowXPTooltip(row)
	if not row or not row.IsShown or not row:IsShown() then
		if row then
			self:HideXPTooltip(row)
		end
		return
	end
	if self.profile and not self.profile.xp then
		self:HideXPTooltip(row)
		return
	end
	if self:InCombat() then
		self:HideXPTooltip(row)
		return
	end
	if not GameTooltip or not GameTooltip.SetOwner or not GameTooltip.AddLine then
		return
	end
	if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
		return
	end
	local lines = self.XPTooltipLines(self:XPTooltipInfo())
	if #lines == 0 then
		self:HideXPTooltip(row)
		return
	end
	if not self:TooltipOwned(row) then
		GameTooltip:SetOwner(row, "ANCHOR_NONE")
	end
	GameTooltip:ClearLines()
	self:AnchorXPTooltip(row)
	for i = 1, #lines do
		local line = lines[i]
		GameTooltip:AddLine(line.text, line.r, line.g, line.b, false)
	end
	GameTooltip:Show()
end

function DiveBar:RefreshXPTooltip()
	local row = self.bar and self.bar.xp
	if not row or not row.tipBound or not row:IsShown() then
		return
	end
	if not self:TooltipOwned(row) then
		return
	end
	self:ShowXPTooltip(row)
end

function DiveBar:SyncXPTooltip()
	local row = self.bar and self.bar.xp
	if not row or not row.tipBound then
		return
	end
	if not row:IsShown() then
		row.xpHover = false
		self:HideXPTooltip(row)
		return
	end
	if row.xpHover then
		self:ShowXPTooltip(row)
	end
end

function DiveBar:PollXPTooltip()
	if self.keepXPTooltip then
		return
	end
	local row = self.bar and self.bar.xp
	if not row or not row.tipBound or row.xpMotion then
		return
	end
	if self:InCombat() then
		if row:IsShown() and self:CursorOver(row) then
			row.xpHover = true
		else
			row.xpHover = false
		end
		self:HideXPTooltip(row)
		return
	end
	if row:IsShown() and self:CursorOver(row) then
		row.xpHover = true
		if not self:TooltipOwned(row) then
			self:ShowXPTooltip(row)
		end
		return
	end
	if row.xpHover or self:TooltipOwned(row) then
		row.xpHover = false
		self:HideXPTooltip(row)
	end
end

function DiveBar:BindXPTooltip(bar)
	local row = bar and bar.xp
	if not row or row.tipBound then
		return
	end
	row.tipBound = true
	row.tipHost = bar
	row:SetScript("OnHide", function(self)
		if DiveBar.keepXPTooltip then
			return
		end
		self.xpHover = false
		DiveBar:HideXPTooltip(self)
	end)
	-- A cover over the fill takes the hover. Clicks pass through to the bar, which stays the drag target.
	if row.SetMouseClickEnabled and row.SetMouseMotionEnabled and type(CreateFrame) == "function" then
		local hover = CreateFrame("Frame", nil, row)
		hover:SetAllPoints(row)
		row.hover = hover
		row.xpMotion = true
		hover:EnableMouse(true)
		hover:SetMouseClickEnabled(false)
		hover:SetMouseMotionEnabled(true)
		if hover.SetPassThroughButtons then
			hover:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
		end
		if hover.SetFrameLevel and row.GetFrameLevel then
			hover:SetFrameLevel((row:GetFrameLevel() or 0) + 5)
		end
		hover:SetScript("OnEnter", function()
			row.xpHover = true
			DiveBar:ShowXPTooltip(row)
		end)
		hover:SetScript("OnLeave", function()
			if DiveBar.keepXPTooltip then
				return
			end
			row.xpHover = false
			DiveBar:HideXPTooltip(row)
		end)
		return
	end
	row:EnableMouse(false)
	if self.xpWatch or type(CreateFrame) ~= "function" then
		return
	end
	local watch = CreateFrame("Frame")
	self.xpWatch = watch
	watch:SetScript("OnUpdate", function()
		DiveBar:PollXPTooltip()
	end)
end
