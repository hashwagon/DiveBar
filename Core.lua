-- Dive Bar
-- The default player cast bar is left to the Blizzard UI.

DiveBar = DiveBar or {}

local ADDON = "DiveBar"

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
DiveBar.VERSION = (GetMetadata and GetMetadata(ADDON, "Version")) or "?"

-- If Forever still refuses a call, keep the function name on the saved data.
local blocked = CreateFrame("Frame")
blocked:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blocked:RegisterEvent("ADDON_ACTION_BLOCKED")
blocked:SetScript("OnEvent", function(_, _, addon, func)
	if addon ~= ADDON then
		return
	end
	local name = tostring(func)
	DiveBar.blockedCall = name
	if type(DiveBarDB) == "table" then
		DiveBarDB.blockedCall = name
	end
end)

function DiveBar:Print(message)
	local line = "|cffffd200Dive Bar|r " .. tostring(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(line)
	else
		print(line)
	end
end

function DiveBar:EnsureDB()
	if type(DiveBarDB) ~= "table" then
		DiveBarDB = {}
	end
	self.db = DiveBarDB
	if type(self.db.profiles) ~= "table" then
		self.db.profiles = {}
	end
	if type(self.db.profileKeys) ~= "table" then
		self.db.profileKeys = {}
	end
	if type(self.db.minimap) ~= "table" then
		self.db.minimap = { hide = false, angle = 225 }
	end
	if type(self.db.minimap.angle) ~= "number" then
		self.db.minimap.angle = 225
	end
	self.db.minimap.hide = self.db.minimap.hide and true or false
	if type(self.db.profiles.Default) ~= "table" then
		self.db.profiles.Default = self.Copy(self.DEFAULTS)
	end
	self.Sanitize(self.db.profiles.Default)
end

function DiveBar:CharKey()
	local name = UnitName("player")
	if not name or name == "" or name == "Unknown" then
		return nil
	end
	return name .. " - " .. (GetRealmName() or "")
end

function DiveBar:ProfileNames()
	local names = {}
	for name in pairs(self.db.profiles) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

function DiveBar:ActiveProfile()
	self:EnsureDB()
	local key = self:CharKey()
	local name = "Default"
	if key then
		name = self.db.profileKeys[key] or "Default"
	end
	if type(self.db.profiles[name]) ~= "table" then
		name = "Default"
		if type(self.db.profiles.Default) ~= "table" then
			self.db.profiles.Default = self.Copy(self.DEFAULTS)
		end
	end
	if key then
		self.db.profileKeys[key] = name
	end
	self.Sanitize(self.db.profiles[name])
	self.OpenIntro(self.db.profiles[name])
	return self.db.profiles[name], name
end

function DiveBar:SetLocked(locked)
	if not self.profile then
		return
	end
	self.SetLockState(self.profile, locked)
	if self.ApplyInteraction then
		self:ApplyInteraction()
	end
end

function DiveBar:Activate()
	self.profile, self.profileName = self:ActiveProfile()
	if self.ApplySuppression then
		self:ApplySuppression()
	end
	if self.Refresh then
		self:Refresh()
	end
	if self.UpdateMinimap then
		self:UpdateMinimap()
	end
	if self.SyncOptions then
		self:SyncOptions()
	end
end

function DiveBar:SwitchProfile(name)
	name = self.CleanName(name)
	if name == "" then
		self:Print("Type a profile name.")
		return
	end
	if name == self.profileName then
		return
	end
	self:EnsureDB()
	if type(self.db.profiles[name]) ~= "table" then
		self.db.profiles[name] = self.Copy(self.profile or self.DEFAULTS)
		self.Sanitize(self.db.profiles[name])
	end
	local key = self:CharKey()
	if key then
		self.db.profileKeys[key] = name
	end
	self:Activate()
	self:Print("Using profile " .. name .. ".")
end

function DiveBar:CreateProfile(name)
	name = self.CleanName(name)
	if name == "" then
		self:Print("Type a profile name.")
		return
	end
	self:EnsureDB()
	if self.db.profiles[name] then
		self:Print("A profile named " .. name .. " already exists.")
		return
	end
	self.db.profiles[name] = self.Copy(self.profile or self.DEFAULTS)
	self.Sanitize(self.db.profiles[name])
	local key = self:CharKey()
	if key then
		self.db.profileKeys[key] = name
	end
	self:Activate()
	self:Print("Created profile " .. name .. ".")
end

function DiveBar:CopyFromProfile(name)
	self:EnsureDB()
	local source = self.db.profiles[name]
	if type(source) ~= "table" then
		return
	end
	local copy = self.Copy(source)
	self.Sanitize(copy)
	self.db.profiles[self.profileName] = copy
	self.profile = copy
	self:Activate()
	self:Print("Copied " .. name .. " onto " .. self.profileName .. ".")
end

function DiveBar:ResetCurrentProfile()
	local name = self.profileName or "Default"
	self.db.profiles[name] = self.Copy(self.DEFAULTS)
	self.Sanitize(self.db.profiles[name])
	self.profile = self.db.profiles[name]
	self:Activate()
	self:Print("Reset profile " .. name .. ".")
end

function DiveBar:DeleteCurrentProfile()
	self:EnsureDB()
	local names = self:ProfileNames()
	if #names <= 1 then
		self:Print("Default is the only profile. Reset it instead.")
		return
	end
	local current = self.profileName
	self.db.profiles[current] = nil
	local nextName = self.db.profiles.Default and "Default" or nil
	if not nextName or nextName == current then
		for profileName in pairs(self.db.profiles) do
			nextName = profileName
			break
		end
	end
	if not nextName then
		self.db.profiles.Default = self.Copy(self.DEFAULTS)
		nextName = "Default"
	end
	local key = self:CharKey()
	if key then
		self.db.profileKeys[key] = nextName
	end
	self:Activate()
	self:Print("Deleted profile " .. current .. ". Using " .. nextName .. ".")
end

function DiveBar:ApplySuppression()
	if self.ApplyBlizzardBars then
		self:ApplyBlizzardBars()
	end
end

function DiveBar:Slash(message)
	message = tostring(message or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local command, rest = message:match("^(%S*)%s*(.*)$")
	command = (command or ""):lower()
	if command == "" or command == "config" or command == "options" then
		self:ToggleOptions()
	elseif command == "lock" then
		self:SetLocked(true)
		self:Refresh()
		self:SyncOptions()
		self:Print("Locked.")
	elseif command == "unlock" then
		self:SetLocked(false)
		self:Refresh()
		self:SyncOptions()
		self:Print("Unlocked.")
	elseif command == "reset" then
		self:ResetCurrentProfile()
	elseif command == "minimap" then
		self.db.minimap.hide = not self.db.minimap.hide
		self:UpdateMinimap()
		self:SyncOptions()
		self:Print(self.db.minimap.hide and "Minimap button hidden." or "Minimap button shown.")
	elseif command == "profile" then
		self:SwitchProfile(rest)
	elseif command == "xpreset" then
		self:ResetXPSession()
		self:Print("Experience session reset.")
	else
		self:Print("Commands: /divebar, lock, unlock, reset, minimap, profile <name>, xpreset")
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON then
		DiveBar:EnsureDB()
		DiveBar.profile, DiveBar.profileName = DiveBar:ActiveProfile()
		DiveBar:CreateUI()
		DiveBar:ApplySuppression()
	elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		DiveBar:OnPlayerReady()
	end
end)

SLASH_DIVEBAR1 = "/divebar"
SlashCmdList.DIVEBAR = function(message)
	DiveBar:Slash(message)
end
