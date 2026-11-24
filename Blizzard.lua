-- Turns Blizzard's cast bar, timer bars, swing timer, and experience bar
-- on or off through the active Edit Mode layout.
-- PlayerCastingBarFrame and CastingBarFrame are never referenced. Touching
-- them raises the blocked-action dialog on this client.

DiveBar = DiveBar or {}

local SYSTEM_NAME = {
	cast = "CastBar",
	timers = "TimerBars",
	swings = "SwingTimer",
	xp = "StatusTrackingBar",
}

local BLIZZARD_NAME = {
	cast = "cast bar",
	timers = "timer bars",
	swings = "swing timer",
	xp = "experience bar",
}

local function SystemId(name)
	local systems = Enum and Enum.EditModeSystem
	if type(systems) ~= "table" then
		return nil
	end
	return systems[name]
end

local function ActiveLayout(layouts)
	if type(layouts) ~= "table" or type(layouts.layouts) ~= "table" then
		return nil
	end
	local layout = layouts.layouts[layouts.activeLayout]
	if type(layout) ~= "table" or type(layout.systems) ~= "table" then
		return nil
	end
	return layout
end

local function IsPreset(layout)
	local kind = Enum and Enum.EditModeLayoutType
	if type(kind) ~= "table" or type(layout) ~= "table" then
		return false
	end
	return layout.layoutType == kind.Preset
end

local function HiddenLabel(text)
	if type(text) ~= "string" then
		return false
	end
	if HUD_EDIT_MODE_SETTING_UNIT_FRAME_HIDDEN and text == HUD_EDIT_MODE_SETTING_UNIT_FRAME_HIDDEN then
		return true
	end
	return text == "Hidden"
end

local function AlwaysLabel(text)
	if type(text) ~= "string" then
		return false
	end
	if HUD_EDIT_MODE_SETTING_UNIT_FRAME_VISIBILITY_ALWAYS and text == HUD_EDIT_MODE_SETTING_UNIT_FRAME_VISIBILITY_ALWAYS then
		return true
	end
	return text == "Always"
end

local function VisibilitySetting(setting)
	if setting == nil or type(Enum) ~= "table" then
		return false
	end
	for key, value in pairs(Enum) do
		if type(key) == "string" and type(value) == "table" and value.Visibility == setting then
			if key:find("EditMode", 1, true) then
				return true
			end
		end
	end
	return false
end

local function Choices(systemId)
	local manager = EditModeSettingDisplayInfoManager
	local map = manager and manager.systemSettingDisplayInfo
	local setups = type(map) == "table" and map[systemId] or nil
	if type(setups) ~= "table" then
		return nil
	end
	for _, setup in pairs(setups) do
		if type(setup) == "table" and type(setup.options) == "table" and setup.setting ~= nil then
			local hidden
			local always
			local minValue
			local maxValue
			for _, option in pairs(setup.options) do
				if type(option) == "table" then
					if HiddenLabel(option.text) then
						hidden = option.value
					elseif always == nil and AlwaysLabel(option.text) then
						always = option.value
					end
					if type(option.value) == "number" then
						if minValue == nil or option.value < minValue then
							minValue = option.value
						end
						if maxValue == nil or option.value > maxValue then
							maxValue = option.value
						end
					end
				end
			end
			if hidden == nil and VisibilitySetting(setup.setting) and maxValue ~= nil and minValue ~= nil and maxValue ~= minValue then
				hidden = maxValue
				always = minValue
			end
			if hidden ~= nil then
				if always == nil then
					always = minValue or 0
				end
				return setup.setting, hidden, always
			end
		end
	end
	return nil
end

local function ReadSetting(system, setting)
	if type(system.settings) ~= "table" then
		return nil
	end
	for _, item in pairs(system.settings) do
		if type(item) == "table" and item.setting == setting then
			return item.value
		end
	end
	return nil
end

local function WriteSetting(system, setting, value)
	if type(system.settings) ~= "table" then
		system.settings = {}
	end
	for _, item in pairs(system.settings) do
		if type(item) == "table" and item.setting == setting then
			if item.value == value then
				return false
			end
			item.value = value
			return true
		end
	end
	system.settings[#system.settings + 1] = { setting = setting, value = value }
	return true
end

local function Join(names)
	if #names == 1 then
		return names[1]
	end
	if #names == 2 then
		return names[1] .. " and " .. names[2]
	end
	local copy = {}
	for i = 1, #names - 1 do
		copy[i] = names[i]
	end
	return table.concat(copy, ", ") .. ", and " .. names[#names]
end

function DiveBar:ApplyBlizzardBars()
	local profile = self.profile
	if not profile then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		self.blizzPending = true
		return
	end
	self.blizzPending = nil
	if C_EditMode and EditModeSettingDisplayInfoManager == nil and not self.blizzWaited then
		self.blizzWaited = true
		self.blizzPending = true
		return
	end
	local note
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts and SystemId("CastBar")) then
		self.blizzNote = "This client can't hide the Blizzard bars."
		return
	end
	local ok, layouts = pcall(C_EditMode.GetLayouts)
	local layout = ok and ActiveLayout(layouts) or nil
	if not layout then
		self.blizzNote = "Can't read the Edit Mode layout, so the Blizzard bars can't be hidden."
		return
	end
	if IsPreset(layout) then
		self.blizzNote = "Save a custom Edit Mode layout to hide Blizzard bars."
		return
	end
	if type(profile.blizzRestore) ~= "table" then
		profile.blizzRestore = {}
	end
	local missing = {}
	local changed = false
	for i = 1, #self.FEATURE_LIST do
		local feature = self.FEATURE_LIST[i]
		local systemId = SystemId(SYSTEM_NAME[feature])
		local setting, hidden, always = Choices(systemId)
		local wantShown = profile[self.BLIZZARD_FLAG[feature]]
		local matched = false
		if systemId and setting ~= nil then
			for _, system in pairs(layout.systems) do
				if type(system) == "table" and system.system == systemId then
					matched = true
					local key = feature .. ":" .. tostring(system.systemIndex)
					local current = ReadSetting(system, setting)
					local target
					if wantShown then
						target = profile.blizzRestore[key]
						if target == nil or target == hidden then
							target = always
						end
					else
						if current ~= nil and current ~= hidden then
							profile.blizzRestore[key] = current
						end
						target = hidden
					end
					if WriteSetting(system, setting, target) then
						changed = true
					end
				end
			end
		end
		if not wantShown and not matched then
			missing[#missing + 1] = BLIZZARD_NAME[feature]
		end
	end
	if changed then
		local saved = pcall(C_EditMode.SaveLayouts, layouts)
		if not saved then
			note = "Can't save the Edit Mode layout."
		end
	end
	if not note and #missing > 0 then
		note = "No hide option for the Blizzard " .. Join(missing) .. "."
	end
	self.blizzNote = note
end
