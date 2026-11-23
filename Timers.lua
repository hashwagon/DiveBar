-- Breath, fatigue, and Feign Death. Blizzard calls these timer bars.
-- They are not weapon swing timers.

DiveBar = DiveBar or {}

DiveBar.TIMER_COLOR = {
	EXHAUSTION = { 1, 0.90, 0 },
	BREATH = { 0, 0.50, 1 },
	DEATH = { 1, 0.70, 0 },
	FEIGNDEATH = { 1, 0.70, 0 },
}

local function Closed(value)
	return issecretvalue and issecretvalue(value) and true or false
end

function DiveBar:MirrorKey()
	local mirrors = self.mirrors or {}
	local parts = {}
	for i = 1, #mirrors do
		parts[i] = mirrors[i].name
	end
	return table.concat(parts, "|")
end

function DiveBar:ReadMirrors()
	local list = {}
	self.mirrors = list
	if type(GetMirrorTimerInfo) ~= "function" then
		return
	end
	local count = MIRRORTIMER_NUMTIMERS or 3
	if count > 3 then
		count = 3
	end
	for i = 1, count do
		local ok, name, initial, maxValue, scale, paused, label = pcall(GetMirrorTimerInfo, i)
		if ok and type(name) == "string" and name ~= "" and name ~= "UNKNOWN" and not Closed(name) then
			local current = initial
			if type(GetMirrorTimerProgress) == "function" then
				local progressOk, progress = pcall(GetMirrorTimerProgress, name)
				if progressOk and type(progress) == "number" and not Closed(progress) then
					current = progress
				end
			end
			if not Closed(current) and not Closed(maxValue) and not Closed(label) then
				local maxSeconds = (tonumber(maxValue) or 0) / 1000
				local seconds = (tonumber(current) or 0) / 1000
				if maxSeconds < 0 then
					maxSeconds = 0
				end
				if seconds < 0 then
					seconds = 0
				elseif maxSeconds > 0 and seconds > maxSeconds then
					seconds = maxSeconds
				end
				local text = label
				if type(text) ~= "string" or text == "" then
					text = name
				end
				list[#list + 1] = {
					name = name,
					label = text,
					value = seconds,
					max = maxSeconds,
					scale = tonumber(scale) or -1,
					paused = (tonumber(paused) or 0) > 0,
				}
			end
		end
	end
end

function DiveBar:PollMirrors()
	local before = self.mirrorKey
	self:ReadMirrors()
	self.mirrorKey = self:MirrorKey()
	return self.mirrorKey ~= before
end
