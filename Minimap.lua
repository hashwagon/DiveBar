-- Minimap button. Left click opens options, right click hides it, drag moves it.

DiveBar = DiveBar or {}

local function Place(button, angle)
	local radians = math.rad(angle or 225)
	local width = (Minimap:GetWidth() / 2) + 8
	local height = (Minimap:GetHeight() / 2) + 8
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * width, math.sin(radians) * height)
end

function DiveBar:CreateMinimap()
	if self.minimap or not Minimap then
		return
	end
	local button = CreateFrame("Button", "DiveBarMinimapButton", Minimap)
	self.minimap = button
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local icon = button:CreateTexture(nil, "ARTWORK")
	-- The tracking ring is a circle. A 20px square's corners cross that ring.
	icon:SetSize(14, 14)
	icon:SetPoint("CENTER", 0, 0)
	icon:SetTexture("Interface\\Icons\\Spell_Frost_FrostBolt02")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")

	button:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then
			DiveBar.db.minimap.hide = true
			DiveBar:UpdateMinimap()
			DiveBar:SyncOptions()
			DiveBar:Print("Minimap button hidden. /divebar minimap shows it again.")
			return
		end
		DiveBar:ToggleOptions()
	end)
	button:SetScript("OnDragStart", function(self)
		self.dragging = true
		self:SetScript("OnUpdate", function(moving)
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			cx, cy = cx / scale, cy / scale
			local angle = math.deg(math.atan2(cy - my, cx - mx))
			DiveBar.db.minimap.angle = angle
			Place(moving, angle)
		end)
	end)
	button:SetScript("OnDragStop", function(self)
		self.dragging = false
		self:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Dive Bar", 1, 0.824, 0)
		GameTooltip:AddLine("Left-click: options", 1, 1, 1)
		GameTooltip:AddLine("Right-click: hide", 1, 1, 1)
		GameTooltip:AddLine("Drag: move around the minimap", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	self:UpdateMinimap()
end

function DiveBar:UpdateMinimap()
	local button = self.minimap
	if not button or not self.db then
		return
	end
	if self.db.minimap.hide then
		button:Hide()
		return
	end
	button:Show()
	Place(button, self.db.minimap.angle)
end
