-- Options window. /divebar and the minimap button open the same page.
-- Chrome comes from Blizzard templates: ButtonFrameTemplate, the panel button,
-- the modern dropdown, and the standard checkbox and edit box.

DiveBar = DiveBar or {}

local controls = {}
local menu
local catcher
local templateSupport = {}

local function Supports(frameType, template)
	local key = frameType .. ":" .. template
	local known = templateSupport[key]
	if known ~= nil then
		return known
	end
	local ok, frame = pcall(CreateFrame, frameType, nil, UIParent, template)
	if ok and frame then
		frame:Hide()
		pcall(frame.SetParent, frame, nil)
		templateSupport[key] = true
		return true
	end
	templateSupport[key] = false
	return false
end

local function ColorTex(texture, r, g, b, a)
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a or 1)
	else
		texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		texture:SetVertexColor(r, g, b, a or 1)
	end
end

local function GoldLabel(parent, text, size)
	local object = (size and size >= 16) and "GameFontNormalLarge" or "GameFontNormal"
	local font = parent:CreateFontString(nil, "OVERLAY", object)
	font:SetText(text)
	font:SetJustifyH("LEFT")
	return font
end

local function Cream(parent, text)
	local font = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	font:SetText(text)
	font:SetJustifyH("LEFT")
	return font
end

local function HideMenu()
	if menu then
		menu:Hide()
	end
	if catcher then
		catcher:Hide()
	end
end

local function EnsureMenu()
	if menu then
		return
	end
	catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN_DIALOG")
	catcher:SetFrameLevel(20)
	catcher:Hide()
	catcher:SetScript("OnClick", HideMenu)

	local ok, created = pcall(CreateFrame, "Frame", nil, UIParent, "BackdropTemplate")
	menu = (ok and created) or CreateFrame("Frame", nil, UIParent)
	menu:SetFrameStrata("TOOLTIP")
	menu:Hide()
	if menu.SetBackdrop then
		menu:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		menu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		menu:SetBackdropBorderColor(1, 1, 1, 1)
	end
	menu.buttons = {}
end

local function ShowMenu(anchor, items, onPick)
	EnsureMenu()
	HideMenu()
	local width = anchor:GetWidth()
	if width < 140 then
		width = 140
	end
	for i = 1, #menu.buttons do
		menu.buttons[i]:Hide()
	end
	local height = 4
	for i = 1, #items do
		local item = items[i]
		local button = menu.buttons[i]
		if not button then
			button = CreateFrame("Button", nil, menu)
			button:SetHeight(20)
			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			button.text:SetPoint("LEFT", 8, 0)
			button.text:SetPoint("RIGHT", -8, 0)
			button.text:SetJustifyH("LEFT")
			button.text:SetTextColor(1, 0.824, 0)
			button:SetScript("OnEnter", function(self)
				self.text:SetTextColor(1, 0.95, 0.7)
			end)
			button:SetScript("OnLeave", function(self)
				self.text:SetTextColor(1, 0.824, 0)
			end)
			menu.buttons[i] = button
		end
		button:SetWidth(width)
		button.text:SetText(item[2])
		button:SetScript("OnClick", function()
			HideMenu()
			onPick(item[1])
		end)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -(6 + (i - 1) * 20))
		button:Show()
		height = height + 20
	end
	menu:SetSize(width + 8, height + 8)
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	menu:SetClampedToScreen(true)
	catcher:Show()
	menu:Show()
end

local function Box(parent, width, height)
	local ok, frame = pcall(CreateFrame, "Frame", nil, parent, "BackdropTemplate")
	if not ok or not frame then
		frame = CreateFrame("Frame", nil, parent)
	end
	frame:SetSize(width, height)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		frame:SetBackdropColor(0, 0, 0, 0.85)
		frame:SetBackdropBorderColor(1, 1, 1, 1)
		return frame
	end
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	ColorTex(bg, 0.08, 0.05, 0.03, 1)
	local top = frame:CreateTexture(nil, "BORDER")
	top:SetPoint("TOPLEFT")
	top:SetPoint("TOPRIGHT")
	top:SetHeight(1)
	ColorTex(top, 0.77, 0.64, 0.42, 1)
	local bottom = frame:CreateTexture(nil, "BORDER")
	bottom:SetPoint("BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT")
	bottom:SetHeight(1)
	ColorTex(bottom, 0.23, 0.16, 0.09, 1)
	return frame
end

local function PaintedButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width or 88, 22)
	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	ColorTex(bg, 0.28, 0.19, 0.09, 1)
	local top = button:CreateTexture(nil, "BORDER")
	top:SetPoint("TOPLEFT")
	top:SetPoint("TOPRIGHT")
	top:SetHeight(1)
	ColorTex(top, 0.95, 0.89, 0.74, 1)
	local bottom = button:CreateTexture(nil, "BORDER")
	bottom:SetPoint("BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT")
	bottom:SetHeight(1)
	ColorTex(bottom, 0.16, 0.1, 0.05, 1)
	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER")
	label:SetText(text)
	button.label = label
	button.bg = bg
	button:SetScript("OnEnter", function()
		if button.enabled ~= false then
			ColorTex(bg, 0.38, 0.26, 0.12, 1)
		end
	end)
	button:SetScript("OnLeave", function()
		ColorTex(bg, button.enabled == false and 0.16 or 0.28, button.enabled == false and 0.12 or 0.19, button.enabled == false and 0.07 or 0.09, 1)
	end)
	function button:SetButtonEnabled(on)
		self.enabled = on and true or false
		self:EnableMouse(self.enabled)
		label:SetTextColor(self.enabled and 1 or 0.45, self.enabled and 0.824 or 0.4, self.enabled and 0 or 0.25)
		ColorTex(bg, self.enabled and 0.28 or 0.16, self.enabled and 0.19 or 0.12, self.enabled and 0.09 or 0.07, 1)
	end
	button:SetButtonEnabled(true)
	return button
end

local function Button(parent, text, width)
	local template
	if Supports("Button", "UIPanelDynamicResizeButtonTemplate") then
		template = "UIPanelDynamicResizeButtonTemplate"
	elseif Supports("Button", "UIPanelButtonTemplate") then
		template = "UIPanelButtonTemplate"
	end
	if not template then
		return PaintedButton(parent, text, width)
	end
	local button = CreateFrame("Button", nil, parent, template)
	button:SetText(text)
	if template == "UIPanelDynamicResizeButtonTemplate" and DynamicResizeButton_Resize then
		DynamicResizeButton_Resize(button)
		if width and button:GetWidth() < width then
			button:SetWidth(width)
		end
	else
		button:SetSize(width or 88, 22)
	end
	function button:SetButtonEnabled(on)
		self.enabled = on and true or false
		if self.enabled then
			self:Enable()
		else
			self:Disable()
		end
	end
	button:SetButtonEnabled(true)
	return button
end

local function Check(parent, text, apply)
	local button = CreateFrame("CheckButton", nil, parent)
	button:SetSize(24, 24)
	button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	local label = Cream(parent, text)
	label:SetPoint("LEFT", button, "RIGHT", 2, 0)
	button.label = label
	button:SetScript("OnClick", function(self)
		if self.dimmed then
			self:SetChecked(not self:GetChecked())
			return
		end
		apply(self:GetChecked() and true or false)
		DiveBar:Refresh()
	end)
	function button:SetDimmed(dim)
		self.dimmed = dim and true or false
		self:EnableMouse(not self.dimmed)
		local alpha = self.dimmed and 0.45 or 1
		self:SetAlpha(alpha)
		label:SetAlpha(alpha)
	end
	controls[#controls + 1] = button
	return button
end

local function DropdownText(dropdown, text)
	if dropdown.Text then
		dropdown.Text:SetText(text)
		return
	end
	if dropdown.GetFontString then
		local font = dropdown:GetFontString()
		if font then
			font:SetText(text)
		end
	end
end

local function ModernDropdown(parent, width, itemsFn, get, apply)
	if not Supports("DropdownButton", "WowStyle1DropdownTemplate") then
		return nil
	end
	local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	if not dropdown.SetupMenu then
		dropdown:Hide()
		dropdown:SetParent(nil)
		return nil
	end
	dropdown:SetWidth(width)
	dropdown:SetupMenu(function(_, root)
		local items = itemsFn()
		for i = 1, #items do
			local value = items[i][1]
			local label = items[i][2]
			root:CreateRadio(label, function()
				return get() == value
			end, function()
				apply(value)
				DiveBar:Refresh()
			end)
		end
	end)
	dropdown.Refresh = function()
		local value = get()
		local label = tostring(value)
		local items = itemsFn()
		for i = 1, #items do
			if items[i][1] == value then
				label = items[i][2]
				break
			end
		end
		DropdownText(dropdown, label)
	end
	function dropdown:SetDimmed(dim)
		local on = not dim
		if self.SetEnabled then
			self:SetEnabled(on)
		else
			self:EnableMouse(on)
		end
		self:SetAlpha(dim and 0.45 or 1)
	end
	controls[#controls + 1] = dropdown
	return dropdown
end

local function Dropdown(parent, width, itemsFn, get, apply)
	local modern = ModernDropdown(parent, width, itemsFn, get, apply)
	if modern then
		return modern
	end
	local box = Box(parent, width, 22)
	local button = CreateFrame("Button", nil, box)
	button:SetAllPoints()
	button.text = GoldLabel(button, "", 12)
	button.text:SetPoint("LEFT", 8, 0)
	button.text:SetPoint("RIGHT", -16, 0)
	button.text:SetJustifyH("LEFT")
	local caret = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	caret:SetPoint("RIGHT", -6, 0)
	caret:SetText("v")
	button:SetScript("OnClick", function()
		ShowMenu(box, itemsFn(), function(value)
			apply(value)
			DiveBar:Refresh()
		end)
	end)
	box.Refresh = function()
		local value = get()
		local label = tostring(value)
		local items = itemsFn()
		for i = 1, #items do
			if items[i][1] == value then
				label = items[i][2]
				break
			end
		end
		button.text:SetText(label)
	end
	function box:SetDimmed(dim)
		button:EnableMouse(not dim)
		box:SetAlpha(dim and 0.45 or 1)
	end
	controls[#controls + 1] = box
	return box
end

-- The sticky preview: heading and tick boxes above the bar, the divider below it.
local PREVIEW_TOP = 34
local PREVIEW_BOTTOM = 6

local SLIDER_W = 270
local THUMB_W = 32
local ARROW_W = 24
local FIELD_W = 64
local SLIDER_GAP = 2

local function StepButton(parent, previous)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(ARROW_W, ARROW_W)
	local name = previous and "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-" or "Interface\\Buttons\\UI-SpellbookIcon-NextPage-"
	button:SetNormalTexture(name .. "Up")
	button:SetPushedTexture(name .. "Down")
	button:SetDisabledTexture(name .. "Disabled")
	button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	function button:SetButtonEnabled(on)
		self.enabled = on and true or false
		if self.enabled then
			self:Enable()
		else
			self:Disable()
		end
	end
	button:SetButtonEnabled(true)
	return button
end

local function Slider(parent, text, low, high, step, get, apply, format)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetSize(SLIDER_W, 50)
	local label = Cream(holder, text)
	label:SetPoint("TOPLEFT", 0, 0)

	local function snap(current)
		if step and step > 0 then
			current = low + math.floor((current - low) / step + 0.5) * step
		end
		if step and step < 1 then
			local places = step < 0.1 and 100 or 10
			current = math.floor(current * places + 0.5) / places
		end
		if current < low then
			current = low
		elseif current > high then
			current = high
		end
		return current
	end

	local function parse(text)
		text = tostring(text or ""):gsub("%s+", "")
		local percent = text:match("^(%d+%.?%d*)%%$")
		if percent then
			return tonumber(percent) / 100
		end
		local number = tonumber(text)
		if number and high <= 1 and number > 1 and number <= 100 then
			number = number / 100
		end
		return number
	end

	local down = StepButton(holder, true)
	down:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
	local up = StepButton(holder, false)
	local box
	if Supports("EditBox", "InputBoxTemplate") then
		box = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
		box:SetSize(FIELD_W, 20)
		box:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
	else
		local field = Box(holder, FIELD_W, 18)
		field:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
		box = CreateFrame("EditBox", nil, field)
		box:SetAllPoints()
		box:SetFontObject(GameFontHighlightSmall)
		box:SetTextInsets(2, 2, 0, 0)
	end
	box:SetAutoFocus(false)
	box:SetJustifyH("CENTER")
	box:SetTextColor(1, 1, 1)

	local trackW = SLIDER_W - ARROW_W - SLIDER_GAP - ARROW_W - SLIDER_GAP - FIELD_W - SLIDER_GAP
	local made, framed = pcall(CreateFrame, "Slider", nil, holder, "BackdropTemplate")
	local slider = (made and framed) or CreateFrame("Slider", nil, holder)
	-- Center the 17px groove on the 24px arrows.
	slider:SetPoint("BOTTOMLEFT", down, "BOTTOMRIGHT", SLIDER_GAP, 3)
	slider:SetSize(trackW, 17)
	slider:SetOrientation("HORIZONTAL")
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	local thumb = slider:GetThumbTexture()
	if thumb then
		thumb:SetSize(THUMB_W, THUMB_W)
	end
	-- This border is a 9-slice. Stretching it as one texture turns the end caps into black bars.
	if slider.SetBackdrop then
		slider:SetBackdrop({
			bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 },
		})
		slider:SetBackdropColor(1, 1, 1, 1)
		slider:SetBackdropBorderColor(1, 1, 1, 1)
	end
	-- The groove starts inside the left cap. The fill ends at the thumb center,
	-- so a full slider meets the button and a minimum slider stays empty.
	local fillStart = 6
	local fill = slider:CreateTexture(nil, "BACKGROUND", nil, 1)
	fill:SetColorTexture(1, 0.78, 0.15, 1)
	fill:SetHeight(4)
	up:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", ARROW_W + SLIDER_GAP + trackW + SLIDER_GAP, 0)
	slider:EnableMouseWheel(false)

	local function paint(current)
		local span = high - low
		local ratio = span > 0 and (current - low) / span or 0
		if ratio < 0 then
			ratio = 0
		elseif ratio > 1 then
			ratio = 1
		end
		fill:ClearAllPoints()
		if ratio <= 0 or not thumb then
			fill:Hide()
		else
			-- The button's art sits inside a wider texture. Ending the fill on
			-- that center meets the button at the top of the slider, and stays
			-- empty at the bottom instead of leaving a stub past the cap.
			fill:SetPoint("LEFT", slider, "LEFT", fillStart, 0)
			fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
			fill:SetHeight(4)
			fill:Show()
		end
		if not box:HasFocus() then
			box:SetText(format(current))
		end
	end
	local function commit(text)
		local number = parse(text)
		if not number then
			paint(slider:GetValue() or low)
			return
		end
		slider:SetValue(snap(number))
	end
	slider:SetScript("OnValueChanged", function(self, current)
		paint(current)
		if self.silent or holder.locked then
			return
		end
		apply(current)
		DiveBar:Refresh()
	end)
	slider:SetScript("OnSizeChanged", function()
		paint(slider:GetValue() or low)
	end)
	box:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	box:SetScript("OnEscapePressed", function(self)
		self.escape = true
		self:ClearFocus()
	end)
	box:SetScript("OnEditFocusLost", function(self)
		if self.escape then
			self.escape = nil
			paint(slider:GetValue() or low)
			return
		end
		commit(self:GetText())
	end)
	local function nudge(direction)
		if holder.locked then
			return
		end
		slider:SetValue(snap((slider:GetValue() or low) + direction * step))
	end
	down:SetScript("OnClick", function()
		nudge(-1)
	end)
	up:SetScript("OnClick", function()
		nudge(1)
	end)
	holder.slider = slider
	holder.Refresh = function()
		slider.silent = true
		local current = get()
		slider:SetValue(current)
		paint(current)
		slider.silent = false
	end
	function holder:SetLocked(locked)
		self.locked = locked and true or false
		local on = not self.locked
		slider:EnableMouse(on)
		down:SetButtonEnabled(on)
		up:SetButtonEnabled(on)
		box:EnableMouse(on)
		if not on then
			box:ClearFocus()
		end
		self:SetAlpha(self.locked and 0.45 or 1)
	end
	controls[#controls + 1] = holder
	return holder
end

local function AddControl(list, widget)
	list[#list + 1] = widget
	return widget
end

function DiveBar:SyncOptions()
	if not self.profile then
		return
	end
	for i = 1, #controls do
		local widget = controls[i]
		if widget.Refresh then
			widget:Refresh()
		end
	end
	local profile = self.profile
	local meleeOn = profile.swings and profile.swingMelee and true or false
	local rangedOn = profile.swings and profile.swingRanged and true or false
	local bothClasses = meleeOn and rangedOn

	local function dim(widget, faded)
		if widget and widget.SetDimmed then
			widget:SetDimmed(faded and true or false)
		end
	end
	local function fade(font, faded)
		if font and font.SetAlpha then
			font:SetAlpha(faded and 0.45 or 1)
		end
	end

	dim(self.consolidateCheck, not bothClasses)
	fade(self.consolidateNote, not bothClasses)
	dim(self.colorMelee, not meleeOn)
	dim(self.colorOff, not meleeOn)
	dim(self.colorShot, not rangedOn)
	dim(self.colorWand, not rangedOn)
	local levelOff = profile.xpLevelTime == "off"
	dim(self.xpBadgeFormat, levelOff)
	fade(self.xpBadgeFormatLabel, levelOff)
	if self.xpLevelTimeSize then
		self.xpLevelTimeSize:SetLocked(profile.xpLevelTime ~= "badge")
	end
	if self.xpBadgeTextSize then
		self.xpBadgeTextSize:SetLocked(levelOff)
	end
	fade(self.xpLevelTimeNote, levelOff)
	if self.blizzNoteText then
		self.blizzNoteText:SetText(self.blizzNote or "")
		self.blizzNoteText:SetShown(self.blizzNote and true or false)
	end
	if self.deleteButton then
		self.deleteButton:SetButtonEnabled(#self:ProfileNames() > 1)
	end
	if self.LayoutFeatureRows then
		self:LayoutFeatureRows()
	end
	if self.LayoutPreviewChecks then
		self:LayoutPreviewChecks()
	end
	if self.LayoutOptions then
		self:LayoutOptions()
	end
end

function DiveBar:LayoutFeatureRows()
	local host = self.featuresHost
	local rows = self.featureRows
	if not host or not rows or not self.profile then
		return
	end
	local order = self.OrderedFeatures(self.profile)
	local y = self.featureRowY or -74
	for i = 1, #order do
		local row = rows[order[i]]
		if row then
			local offset = y - (i - 1) * 30
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", host, "TOPLEFT", 0, offset)
			row:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, offset)
		end
	end
end

function DiveBar:LayoutOptions()
	local body = self.optionsBody
	if not body or not self.profile or not self.featuresHost then
		return
	end
	local extra = self.blizzNote and 22 or 0
	self.featuresHost:SetHeight((self.featuresBase or 280) + extra)
	local hosts = { self.featuresHost, self.lookHost }
	local order = self.OrderedFeatures(self.profile)
	for i = 1, #order do
		local host = self.detailHosts and self.detailHosts[order[i]]
		if host then
			hosts[#hosts + 1] = host
		end
	end
	if self.profileHost then
		hosts[#hosts + 1] = self.profileHost
	end
	local y = 0
	for i = 1, #hosts do
		local host = hosts[i]
		local show = true
		if host.feature then
			show = self.profile[host.feature] and true or false
		end
		host:SetShown(show)
		if show then
			host:ClearAllPoints()
			host:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
			host:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, y)
			y = y - (host:GetHeight() or 0) - 8
		end
	end
	local height = -y + 4
	if height < 8 then
		height = 8
	end
	body:SetHeight(height)
	self.previewBodyHeight = height
	if self.FitPreview then
		self:FitPreview()
	end
end

function DiveBar:BuildOptionSections(body)
	local function Header(parent, text, y)
		local font = GoldLabel(parent, text, 16)
		font:SetPoint("TOPLEFT", 8, y)
		local line = parent:CreateTexture(nil, "ARTWORK")
		line:SetPoint("TOPLEFT", 8, y - 18)
		line:SetSize(600, 1)
		ColorTex(line, 1, 0.82, 0, 0.4)
		return y - 32
	end

	local function Host(feature)
		local host = CreateFrame("Frame", nil, body)
		host.feature = feature
		host:SetHeight(32)
		return host
	end

	local function PaddingSlider(host, feature, y)
		local key = DiveBar.PADDING_KEY[feature]
		local slider = Slider(host, "Padding", 0, 20, 1, function()
			return DiveBar.profile[key]
		end, function(value)
			DiveBar.profile[key] = math.floor(value + 0.5)
		end, function(value)
			return tostring(math.floor(value + 0.5))
		end)
		slider:SetPoint("TOPLEFT", 310, y)
		return slider
	end

	local features = Host(nil)
	self.featuresHost = features
	local y = Header(features, "Bars", -4)
	local featureNote = Cream(features, "Top of the frame is first. The anchor stays put. Bars above and below it show up while they are in use.")
	featureNote:SetPoint("TOPLEFT", 8, y)
	featureNote:SetWidth(600)
	y = y - 32
	self.featureRowY = y
	self.featureRows = {}

	local function FeatureIndex(feature)
		local order = DiveBar.OrderedFeatures(DiveBar.profile)
		for i = 1, #order do
			if order[i] == feature then
				return i, #order
			end
		end
		return 1, #order
	end

	for n = 1, #DiveBar.FEATURE_LIST do
		local feature = DiveBar.FEATURE_LIST[n]
		local flag = DiveBar.BLIZZARD_FLAG[feature]
		local row = CreateFrame("Frame", nil, features)
		row:SetHeight(28)
		local enable = Check(row, DiveBar.FEATURE_LABEL[feature], function(value)
			DiveBar.profile[feature] = value
			if not value then
				DiveBar.profile.anchor = DiveBar.NormalizeAnchor(DiveBar.profile)
			end
		end)
		enable:SetPoint("TOPLEFT", 4, -2)
		enable.Refresh = function()
			enable:SetChecked(DiveBar.profile[feature])
		end
		local blizz = Check(row, "Blizzard bar", function(value)
			DiveBar.profile[flag] = value
			DiveBar:ApplySuppression()
		end)
		blizz:SetPoint("TOPLEFT", 200, -2)
		blizz.Refresh = function()
			blizz:SetChecked(DiveBar.profile[flag])
		end
		local anchor = Button(row, "Anchor", 100)
		anchor:SetPoint("TOPLEFT", 372, -4)
		anchor:SetScript("OnClick", function()
			if not DiveBar.profile[feature] or DiveBar.profile.anchor == feature then
				return
			end
			DiveBar.profile.anchor = feature
			DiveBar:Refresh()
		end)
		local up = Button(row, "Up", 40)
		up:SetPoint("TOPLEFT", 478, -4)
		up:SetScript("OnClick", function()
			DiveBar.MoveFeature(DiveBar.profile, feature, -1)
			DiveBar:Refresh()
		end)
		local down = Button(row, "Down", 52)
		down:SetPoint("LEFT", up, "RIGHT", 4, 0)
		down:SetScript("OnClick", function()
			DiveBar.MoveFeature(DiveBar.profile, feature, 1)
			DiveBar:Refresh()
		end)
		row.Refresh = function()
			local index, count = FeatureIndex(feature)
			local on = DiveBar.profile[feature] and true or false
			local selected = DiveBar.profile.anchor == feature
			anchor:SetText(selected and "Anchored" or "Anchor")
			anchor:SetWidth(100)
			anchor:SetButtonEnabled(on and not selected)
			up:SetButtonEnabled(index > 1)
			down:SetButtonEnabled(index < count)
		end
		controls[#controls + 1] = row
		self.featureRows[feature] = row
	end
	y = y - (#DiveBar.FEATURE_LIST * 30) - 4
	local always = Check(features, "Always show bars", function(value)
		DiveBar.profile.alwaysShow = value
	end)
	always:SetPoint("TOPLEFT", 4, y)
	always.Refresh = function()
		always:SetChecked(DiveBar.profile.alwaysShow)
	end
	y = y - 24
	local alwaysNote = Cream(features, "Show every enabled bar while idle. Off, a bar appears only while it is in use.")
	alwaysNote:SetPoint("TOPLEFT", 32, y)
	alwaysNote:SetWidth(560)
	y = y - 28
	local blizzNote = Cream(features, "")
	blizzNote:SetPoint("TOPLEFT", 8, y)
	blizzNote:SetWidth(600)
	blizzNote:Hide()
	self.blizzNoteText = blizzNote
	self.featuresBase = -y + 8
	features:SetHeight(self.featuresBase)

	local look = Host(nil)
	self.lookHost = look
	y = Header(look, "Look", -4)
	local themeDrop = Dropdown(look, 180, function()
		return {
			{ "Forever", "Forever" },
			{ "Flat", "Flat" },
			{ "Classic", "Classic" },
		}
	end, function()
		return DiveBar.profile.theme
	end, function(value)
		DiveBar.profile.theme = value
	end)
	local themeLabel = Cream(look, "Theme")
	themeLabel:SetPoint("TOPLEFT", 8, y)
	themeDrop:SetPoint("LEFT", themeLabel, "RIGHT", 12, 0)
	y = y - 32
	local widthSlider = Slider(look, "Width", 160, 1440, 1, function()
		return DiveBar.profile.width
	end, function(value)
		DiveBar.profile.width = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	widthSlider:SetPoint("TOPLEFT", 8, y)
	y = y - 58
	local scaleSlider = Slider(look, "Scale", 0.5, 2, 0.05, function()
		return DiveBar.profile.scale
	end, function(value)
		DiveBar.profile.scale = math.floor(value * 20 + 0.5) / 20
	end, function(value)
		return string.format("%.2f", value)
	end)
	scaleSlider:SetPoint("TOPLEFT", 8, y)
	local opacitySlider = Slider(look, "Opacity", 0.2, 1, 0.05, function()
		return DiveBar.profile.opacity
	end, function(value)
		DiveBar.profile.opacity = math.floor(value * 20 + 0.5) / 20
	end, function(value)
		return tostring(math.floor(value * 100 + 0.5)) .. "%"
	end)
	opacitySlider:SetPoint("TOPLEFT", 310, y)
	y = y - 58
	local textSlider = Slider(look, "Text size", 8, 24, 1, function()
		return DiveBar.profile.textSize
	end, function(value)
		DiveBar.profile.textSize = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	textSlider:SetPoint("TOPLEFT", 8, y)
	local borderSlider = Slider(look, "Border", 1, 20, 0.5, function()
		return DiveBar.profile.border
	end, function(value)
		DiveBar.profile.border = math.floor(value * 2 + 0.5) / 2
	end, function(value)
		return string.format("%.1f", value)
	end)
	borderSlider:SetPoint("TOPLEFT", 310, y)
	y = y - 58
	local marginSlider = Slider(look, "Background margin", 0, 20, 1, function()
		return DiveBar.profile.margin
	end, function(value)
		DiveBar.profile.margin = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	marginSlider:SetPoint("TOPLEFT", 8, y)
	y = y - 58
	local lock = Check(look, "Lock", function(value)
		DiveBar:SetLocked(value)
	end)
	lock:SetPoint("TOPLEFT", 4, y)
	lock.Refresh = function()
		lock:SetChecked(DiveBar.profile.lock)
	end
	local minimap = Check(look, "Minimap button", function(value)
		DiveBar.db.minimap.hide = not value
		DiveBar:UpdateMinimap()
	end)
	minimap:SetPoint("LEFT", lock.label, "RIGHT", 24, 0)
	minimap.Refresh = function()
		minimap:SetChecked(not DiveBar.db.minimap.hide)
	end
	local corners = Check(look, "Rounded corners", function(value)
		DiveBar.profile.roundedCorners = value
	end)
	corners:SetPoint("LEFT", minimap.label, "RIGHT", 24, 0)
	corners.Refresh = function()
		corners:SetChecked(DiveBar.profile.roundedCorners)
	end
	y = y - 32
	look:SetHeight(-y + 4)

	self.detailHosts = {}

	local castHost = Host("cast")
	self.detailHosts.cast = castHost
	y = Header(castHost, "Cast bar", -4)
	local showIcon = Check(castHost, "Icon", function(value)
		DiveBar.profile.showIcon = value
	end)
	showIcon:SetPoint("TOPLEFT", 4, y)
	showIcon.Refresh = function()
		showIcon:SetChecked(DiveBar.profile.showIcon)
	end
	local showName = Check(castHost, "Spell name", function(value)
		DiveBar.profile.showName = value
	end)
	showName:SetPoint("LEFT", showIcon.label, "RIGHT", 18, 0)
	showName.Refresh = function()
		showName:SetChecked(DiveBar.profile.showName)
	end
	local showTime = Check(castHost, "Time", function(value)
		DiveBar.profile.showTime = value
	end)
	showTime:SetPoint("LEFT", showName.label, "RIGHT", 18, 0)
	showTime.Refresh = function()
		showTime:SetChecked(DiveBar.profile.showTime)
	end
	local showLatency = Check(castHost, "Latency", function(value)
		DiveBar.profile.showLatency = value
	end)
	showLatency:SetPoint("LEFT", showTime.label, "RIGHT", 18, 0)
	showLatency.Refresh = function()
		showLatency:SetChecked(DiveBar.profile.showLatency)
	end
	y = y - 36
	local castHeight = Slider(castHost, "Height", 12, 48, 1, function()
		return DiveBar.profile.castHeight
	end, function(value)
		DiveBar.profile.castHeight = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	castHeight:SetPoint("TOPLEFT", 8, y)
	PaddingSlider(castHost, "cast", y)
	y = y - 58
	castHost:SetHeight(-y + 4)

	local timerHost = Host("timers")
	self.detailHosts.timers = timerHost
	y = Header(timerHost, "Timers", -4)
	local timerNote = Cream(timerHost, "Breath, fatigue, and Feign Death.")
	timerNote:SetPoint("TOPLEFT", 8, y)
	timerNote:SetWidth(560)
	y = y - 24
	local timerHeight = Slider(timerHost, "Height", 3, 40, 1, function()
		return DiveBar.profile.timerHeight
	end, function(value)
		DiveBar.profile.timerHeight = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	timerHeight:SetPoint("TOPLEFT", 8, y)
	PaddingSlider(timerHost, "timers", y)
	y = y - 58
	timerHost:SetHeight(-y + 4)

	local swingHost = Host("swings")
	self.detailHosts.swings = swingHost
	y = Header(swingHost, "Swing timers", -4)
	local melee = Check(swingHost, "Melee", function(value)
		DiveBar.profile.swingMelee = value
	end)
	melee:SetPoint("TOPLEFT", 4, y)
	melee.Refresh = function()
		melee:SetChecked(DiveBar.profile.swingMelee)
	end
	self.meleeCheck = melee
	local ranged = Check(swingHost, "Ranged and wand", function(value)
		DiveBar.profile.swingRanged = value
	end)
	ranged:SetPoint("LEFT", melee.label, "RIGHT", 18, 0)
	ranged.Refresh = function()
		ranged:SetChecked(DiveBar.profile.swingRanged)
	end
	self.rangedCheck = ranged
	y = y - 34
	local thick = Slider(swingHost, "Height", 3, 40, 1, function()
		return DiveBar.profile.swingHeight
	end, function(value)
		DiveBar.profile.swingHeight = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	thick:SetPoint("TOPLEFT", 8, y)
	PaddingSlider(swingHost, "swings", y)
	y = y - 58
	local consolidate = Check(swingHost, "Single weapon timer", function(value)
		DiveBar.profile.consolidate = value
	end)
	consolidate:SetPoint("TOPLEFT", 4, y)
	consolidate.Refresh = function()
		consolidate:SetChecked(DiveBar.profile.consolidate)
	end
	self.consolidateCheck = consolidate
	y = y - 24
	local consolidateNote = Cream(swingHost, "Shooting replaces melee. A melee swing replaces the ranged timer.")
	consolidateNote:SetPoint("TOPLEFT", 32, y)
	consolidateNote:SetWidth(540)
	self.consolidateNote = consolidateNote
	y = y - 28
	local colorLabel = Cream(swingHost, "Colors")
	colorLabel:SetPoint("TOPLEFT", 8, y)
	y = y - 24
	local function OpenTimerColor(key)
		local color = DiveBar.profile.colors[key]
		local previous = { color[1], color[2], color[3] }
		local function read()
			if ColorPickerFrame.GetColorRGB then
				return ColorPickerFrame:GetColorRGB()
			end
			return previous[1], previous[2], previous[3]
		end
		local function apply()
			local r, g, b = read()
			DiveBar.profile.colors[key] = { r, g, b }
			DiveBar:Refresh()
		end
		local function cancel(restore)
			local r, g, b = previous[1], previous[2], previous[3]
			if type(restore) == "table" then
				r = restore.r or restore[1] or r
				g = restore.g or restore[2] or g
				b = restore.b or restore[3] or b
			end
			DiveBar.profile.colors[key] = { r, g, b }
			DiveBar:Refresh()
		end
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow({
				r = color[1],
				g = color[2],
				b = color[3],
				hasOpacity = false,
				swatchFunc = apply,
				cancelFunc = cancel,
			})
			return
		end
		ColorPickerFrame.func = apply
		ColorPickerFrame.cancelFunc = cancel
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.opacity = 1
		ColorPickerFrame.previousValues = previous
		ColorPickerFrame:SetColorRGB(color[1], color[2], color[3])
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
	end
	local function Swatch(key, text, x)
		local button
		local made, framed = pcall(CreateFrame, "Button", nil, swingHost, "BackdropTemplate")
		if made and framed then
			button = framed
		else
			button = CreateFrame("Button", nil, swingHost)
		end
		button:SetSize(26, 26)
		button:SetPoint("TOPLEFT", x, y)
		local fill = button:CreateTexture(nil, "ARTWORK")
		if button.SetBackdrop then
			button:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 8,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			})
			button:SetBackdropBorderColor(1, 1, 1, 1)
			fill:SetPoint("TOPLEFT", 4, -4)
			fill:SetPoint("BOTTOMRIGHT", -4, 4)
		else
			local edge = button:CreateTexture(nil, "BACKGROUND")
			edge:SetAllPoints()
			edge:SetColorTexture(0.95, 0.82, 0.55, 1)
			fill:SetPoint("TOPLEFT", 2, -2)
			fill:SetPoint("BOTTOMRIGHT", -2, 2)
		end
		fill:SetColorTexture(1, 1, 1, 1)
		local label = Cream(swingHost, text)
		label:SetPoint("LEFT", button, "RIGHT", 6, 0)
		button:SetScript("OnClick", function()
			if button.dimmed then
				return
			end
			OpenTimerColor(key)
		end)
		button.Refresh = function()
			local picked = DiveBar.profile.colors[key]
			fill:SetColorTexture(picked[1], picked[2], picked[3], 1)
		end
		function button:SetDimmed(dim)
			self.dimmed = dim and true or false
			self:EnableMouse(not self.dimmed)
			local alpha = self.dimmed and 0.45 or 1
			self:SetAlpha(alpha)
			label:SetAlpha(alpha)
		end
		controls[#controls + 1] = button
		return button
	end
	self.colorMelee = Swatch("melee", "Melee", 8)
	self.colorOff = Swatch("off", "Off hand", 148)
	self.colorShot = Swatch("shot", "Ranged", 300)
	self.colorWand = Swatch("wand", "Wand", 450)
	y = y - 36
	swingHost:SetHeight(-y + 4)

	local xpHost = Host("xp")
	self.detailHosts.xp = xpHost
	y = Header(xpHost, "Experience", -4)
	local xpHeight = Slider(xpHost, "Height", 2, 40, 0.5, function()
		return DiveBar.profile.xpHeight
	end, function(value)
		DiveBar.profile.xpHeight = math.floor(value * 2 + 0.5) / 2
	end, function(value)
		return string.format("%.1f", value)
	end)
	xpHeight:SetPoint("TOPLEFT", 8, y)
	PaddingSlider(xpHost, "xp", y)
	y = y - 58
	local questXP = Check(xpHost, "Completed quest XP", function(value)
		DiveBar.profile.showQuestXP = value
		if DiveBar.ReadXP then
			DiveBar:ReadXP()
		end
	end)
	questXP:SetPoint("TOPLEFT", 4, y)
	questXP.Refresh = function()
		questXP:SetChecked(DiveBar.profile.showQuestXP)
	end
	y = y - 24
	local questNote = Cream(xpHost, "Yellow bar for quests that are ready to turn in.")
	questNote:SetPoint("TOPLEFT", 32, y)
	questNote:SetWidth(540)
	y = y - 22
	local xpRate = Check(xpHost, "XP per hour in tooltip", function(value)
		DiveBar.profile.showXPRate = value
		DiveBar:RefreshXPTooltip()
	end)
	xpRate:SetPoint("TOPLEFT", 4, y)
	xpRate.Refresh = function()
		xpRate:SetChecked(DiveBar.profile.showXPRate)
	end
	y = y - 24
	local rateNote = Cream(xpHost, "Session XP, XP per hour, time to level and kills to level.")
	rateNote:SetPoint("TOPLEFT", 32, y)
	rateNote:SetWidth(540)
	y = y - 22
	local styleDrop = Dropdown(xpHost, 140, function()
		return {
			{ "badge", "Badge" },
			{ "text", "Text" },
			{ "off", "Off" },
		}
	end, function()
		return DiveBar.profile.xpLevelTime
	end, function(value)
		DiveBar.profile.xpLevelTime = value
	end)
	local styleLabel = Cream(xpHost, "Time to level")
	styleLabel:SetPoint("TOPLEFT", 8, y - 4)
	styleDrop:SetPoint("LEFT", styleLabel, "RIGHT", 12, 0)
	local formatDrop = Dropdown(xpHost, 200, function()
		return {
			{ "decimal", "Decimal (2.6h)" },
			{ "clock", "Hours and minutes (2h 37m)" },
		}
	end, function()
		return DiveBar.profile.xpBadgeFormat
	end, function(value)
		DiveBar.profile.xpBadgeFormat = value
	end)
	local formatLabel = Cream(xpHost, "Format")
	formatLabel:SetPoint("TOPLEFT", 310, y - 4)
	formatDrop:SetPoint("LEFT", formatLabel, "RIGHT", 12, 0)
	self.xpBadgeFormat = formatDrop
	self.xpBadgeFormatLabel = formatLabel
	y = y - 32
	local textSize = Slider(xpHost, "Text size", 4, 24, 1, function()
		return DiveBar.profile.xpBadgeTextSize
	end, function(value)
		DiveBar.profile.xpBadgeTextSize = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	textSize:SetPoint("TOPLEFT", 8, y)
	self.xpBadgeTextSize = textSize
	local levelSize = Slider(xpHost, "Badge padding", 0, 24, 1, function()
		return DiveBar.profile.xpLevelTimeSize
	end, function(value)
		DiveBar.profile.xpLevelTimeSize = math.floor(value + 0.5)
	end, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	levelSize:SetPoint("TOPLEFT", 310, y)
	self.xpLevelTimeSize = levelSize
	y = y - 58
	local levelNote = Cream(xpHost, "Ends where your experience ends. Shows an infinity sign until you earn experience this session. Text size sets the time. Badge padding sets the room around it, so large text can sit in a snug badge.")
	levelNote:SetPoint("TOPLEFT", 8, y)
	levelNote:SetWidth(560)
	self.xpLevelTimeNote = levelNote
	y = y - 34
	xpHost:SetHeight(-y + 4)

	local profiles = Host(nil)
	self.profileHost = profiles
	y = Header(profiles, "Profiles", -4)
	local profileNote = Cream(profiles, "Each character starts on Default. Profiles are saved for the account.")
	profileNote:SetPoint("TOPLEFT", 8, y)
	profileNote:SetWidth(540)
	y = y - 24
	local currentLabel = Cream(profiles, "Profile")
	currentLabel:SetPoint("TOPLEFT", 8, y)
	local current = Dropdown(profiles, 200, function()
		local items = {}
		local names = DiveBar:ProfileNames()
		for i = 1, #names do
			items[#items + 1] = { names[i], names[i] }
		end
		return items
	end, function()
		return DiveBar.profileName
	end, function(value)
		DiveBar:SwitchProfile(value)
	end)
	current:SetPoint("LEFT", currentLabel, "RIGHT", 12, 0)
	y = y - 36
	local nameBox
	if Supports("EditBox", "InputBoxTemplate") then
		nameBox = CreateFrame("EditBox", nil, profiles, "InputBoxTemplate")
		nameBox:SetSize(184, 20)
	else
		nameBox = CreateFrame("EditBox", nil, profiles)
		nameBox:SetSize(180, 22)
		nameBox:SetFontObject(GameFontHighlight)
		nameBox:SetTextInsets(6, 6, 0, 0)
		local nameBG = nameBox:CreateTexture(nil, "BACKGROUND")
		nameBG:SetAllPoints()
		ColorTex(nameBG, 0.08, 0.05, 0.03, 1)
	end
	nameBox:SetPoint("TOPLEFT", 8, y)
	nameBox:SetAutoFocus(false)
	nameBox:SetMaxLetters(24)
	nameBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	nameBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		DiveBar:CreateProfile(self:GetText())
		self:SetText("")
	end)
	local newButton = Button(profiles, "New", 64)
	newButton:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
	newButton:SetScript("OnClick", function()
		DiveBar:CreateProfile(nameBox:GetText())
		nameBox:SetText("")
		nameBox:ClearFocus()
	end)
	local copyLabel = Cream(profiles, "Copy from")
	copyLabel:SetPoint("LEFT", newButton, "RIGHT", 16, 0)
	self.copyName = self.profileName
	local copyDrop = Dropdown(profiles, 140, function()
		local items = {}
		local names = DiveBar:ProfileNames()
		for i = 1, #names do
			items[#items + 1] = { names[i], names[i] }
		end
		return items
	end, function()
		if not DiveBar.db.profiles[DiveBar.copyName] then
			DiveBar.copyName = DiveBar.profileName
		end
		return DiveBar.copyName or DiveBar.profileName
	end, function(value)
		DiveBar.copyName = value
	end)
	copyDrop:SetPoint("LEFT", copyLabel, "RIGHT", 8, 0)
	y = y - 32
	local copyButton = Button(profiles, "Copy", 64)
	copyButton:SetPoint("TOPLEFT", 8, y)
	copyButton:SetScript("OnClick", function()
		if DiveBar.copyName then
			DiveBar:CopyFromProfile(DiveBar.copyName)
		end
	end)
	local resetButton = Button(profiles, "Reset", 64)
	resetButton:SetPoint("LEFT", copyButton, "RIGHT", 8, 0)
	resetButton:SetScript("OnClick", function()
		local dialog = StaticPopup_Show("DIVEBAR_CONFIRM", "Reset " .. DiveBar.profileName .. " to default settings?")
		if dialog then
			dialog.data = {
				fn = function()
					DiveBar:ResetCurrentProfile()
				end,
			}
		end
	end)
	local deleteButton = Button(profiles, "Delete", 64)
	deleteButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0)
	deleteButton:SetScript("OnClick", function()
		local dialog = StaticPopup_Show("DIVEBAR_CONFIRM", "Delete profile " .. DiveBar.profileName .. "?")
		if dialog then
			dialog.data = {
				fn = function()
					DiveBar:DeleteCurrentProfile()
				end,
			}
		end
	end)
	self.deleteButton = deleteButton
	y = y - 32
	local version = Cream(profiles, "Dive Bar " .. self.VERSION)
	version:SetPoint("TOPLEFT", 8, y)
	y = y - 22
	profiles:SetHeight(-y + 4)
	self:LayoutFeatureRows()
end

-- Order follows the Bars section, right-aligned on the Preview heading.
function DiveBar:LayoutPreviewChecks()
	local header = self.previewHeader
	local checks = self.previewChecks
	if not header or not checks or not self.profile then
		return
	end
	local order = self.OrderedFeatures(self.profile)
	local right = 608
	for i = #order, 1, -1 do
		local check = checks[order[i]]
		if check then
			local left = right - math.ceil(check.label:GetStringWidth() or 0) - 2 - 24
			check:ClearAllPoints()
			check:SetPoint("TOPLEFT", header, "TOPLEFT", left, -4)
			right = left - 14
		end
	end
end

function DiveBar:FitPreview()
	local header = self.previewHeader
	local holder = self.previewHolder
	local bar = self.preview
	local scrollContent = self.optionsContent
	if not header or not holder or not bar or not scrollContent then
		return
	end
	local empty = self.previewEmpty and true or false
	bar:SetShown(not empty)
	if self.previewEmptyText then
		self.previewEmptyText:SetShown(empty)
	end
	local height = empty and 16 or (bar:GetHeight() or 0)
	if height < 8 then
		height = 8
	end
	-- A little air above and below the bar, and no empty block under it.
	local holderHeight = math.floor(height + 12 + 0.5)
	local headerHeight = PREVIEW_TOP + holderHeight + PREVIEW_BOTTOM
	local total = 4 + (self.previewBodyHeight or 0) + 8
	if math.abs((holder:GetHeight() or 0) - holderHeight) < 0.5 and math.abs((header:GetHeight() or 0) - headerHeight) < 0.5 and math.abs((scrollContent:GetHeight() or 0) - total) < 0.5 then
		return
	end
	holder:SetHeight(holderHeight)
	header:SetHeight(headerHeight)
	scrollContent:SetHeight(total)
	if self.UpdateOptionsScroll then
		self.UpdateOptionsScroll()
	end
end

function DiveBar:CreateOptions()
	if self.options then
		return
	end
	local panel
	local modernFrame = false
	local ok, created = pcall(CreateFrame, "Frame", "DiveBarOptions", UIParent, "ButtonFrameTemplate")
	if ok and created then
		panel = created
		modernFrame = true
	else
		ok, created = pcall(CreateFrame, "Frame", "DiveBarOptions", UIParent, "BackdropTemplate")
		panel = (ok and created) or CreateFrame("Frame", "DiveBarOptions", UIParent)
	end
	self.options = panel
	panel:SetSize(720, 660)
	panel:SetFrameStrata("DIALOG")
	panel:SetClampedToScreen(true)
	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	panel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	panel:Hide()

	local listed = false
	for i = 1, #UISpecialFrames do
		if UISpecialFrames[i] == "DiveBarOptions" then
			listed = true
			break
		end
	end
	if not listed then
		UISpecialFrames[#UISpecialFrames + 1] = "DiveBarOptions"
	end

	local contentTop, contentLeft, contentRight, contentBottom
	if modernFrame then
		if type(ButtonFrameTemplate_HidePortrait) == "function" then
			pcall(ButtonFrameTemplate_HidePortrait, panel)
		end
		if type(ButtonFrameTemplate_HideButtonBar) == "function" then
			pcall(ButtonFrameTemplate_HideButtonBar, panel)
		end
		if panel.Inset then
			panel.Inset:Hide()
		end
		pcall(function()
			if panel.SetTitle then
				panel:SetTitle("DiveBar")
			end
			if panel.TitleContainer and panel.TitleContainer.TitleText then
				panel.TitleContainer.TitleText:SetText("DiveBar")
			end
			if panel.TitleText then
				panel.TitleText:SetText("DiveBar")
			end
		end)
		local function BindClose(button)
			if not button or button.diveBarClose then
				return
			end
			button.diveBarClose = true
			button:SetScript("OnClick", function()
				panel:Hide()
			end)
			local level = (panel:GetFrameLevel() or 1) + 30
			if panel.TitleContainer and panel.TitleContainer.GetFrameLevel then
				level = math.max(level, (panel.TitleContainer:GetFrameLevel() or 1) + 5)
			end
			button:SetFrameLevel(level)
		end
		if panel.TitleContainer then
			panel.TitleContainer:EnableMouse(true)
			panel.TitleContainer:RegisterForDrag("LeftButton")
			panel.TitleContainer:SetScript("OnDragStart", function()
				panel:StartMoving()
			end)
			panel.TitleContainer:SetScript("OnDragStop", function()
				panel:StopMovingOrSizing()
			end)
		end
		BindClose(panel.CloseButton)
		if panel.TitleContainer then
			BindClose(panel.TitleContainer.CloseButton)
		end
		BindClose(_G[panel:GetName() and (panel:GetName() .. "CloseButton")])
		contentLeft, contentTop, contentRight, contentBottom = 14, -34, -32, 16
	else
		if panel.SetBackdrop then
			panel:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 },
			})
		end
		local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOP", 0, -14)
		title:SetText("DiveBar")
		local closeOk, close = pcall(CreateFrame, "Button", nil, panel, "UIPanelCloseButton")
		if closeOk and close then
			close:SetPoint("TOPRIGHT", 4, 4)
			close:SetScript("OnClick", function()
				panel:Hide()
			end)
		end
		contentLeft, contentTop, contentRight, contentBottom = 22, -42, -40, 20
	end
	-- Sections lay out 600 wide from x = 8, so this leaves the same 8px on the right.
	panel:SetWidth(616 + contentLeft - contentRight)

	ok, created = pcall(CreateFrame, "ScrollFrame", "DiveBarOptionsScroll", panel, "UIPanelScrollFrameTemplate")
	local scroll = (ok and created) or CreateFrame("ScrollFrame", "DiveBarOptionsScroll", panel)
	local templatedScroll = _G.DiveBarOptionsScrollScrollBar ~= nil
	scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", contentLeft, contentTop)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", contentRight, contentBottom)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetWidth(640)
	scroll:SetScrollChild(content)

	local scrollBar = _G.DiveBarOptionsScrollScrollBar
	local function UpdateScroll()
		local width = scroll:GetWidth()
		if width and width > 200 then
			content:SetWidth(width)
		end
		if scroll.UpdateScrollChildRect then
			scroll:UpdateScrollChildRect()
		end
		if templatedScroll or not scrollBar then
			return
		end
		local range = content:GetHeight() - scroll:GetHeight()
		if range < 1 then
			range = 0
		end
		scrollBar:SetMinMaxValues(0, range)
		if range == 0 then
			scrollBar:Hide()
			scroll:SetVerticalScroll(0)
		else
			scrollBar:Show()
		end
	end
	if not templatedScroll then
		local barOk, bar = pcall(CreateFrame, "Slider", nil, scroll, "UIPanelScrollBarTemplate")
		if not barOk or not bar then
			bar = CreateFrame("Slider", nil, scroll)
			bar:SetWidth(16)
			bar:SetOrientation("VERTICAL")
			bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
			local knob = bar:GetThumbTexture()
			if knob then
				knob:SetSize(16, 24)
			end
		end
		scrollBar = bar
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, -16)
		scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 16)
		scrollBar:SetMinMaxValues(0, 1)
		scrollBar:SetValueStep(1)
		scrollBar:SetValue(0)
		scrollBar:SetScript("OnValueChanged", function(self, value)
			scroll:SetVerticalScroll(value)
		end)
		scroll:EnableMouseWheel(true)
		scroll:SetScript("OnMouseWheel", function(self, delta)
			local nextValue = scrollBar:GetValue() - delta * 36
			local _, maxValue = scrollBar:GetMinMaxValues()
			if nextValue < 0 then
				nextValue = 0
			elseif nextValue > maxValue then
				nextValue = maxValue
			end
			scrollBar:SetValue(nextValue)
		end)
	end

	local header = CreateFrame("Frame", nil, panel)
	header:SetPoint("TOPLEFT", panel, "TOPLEFT", contentLeft, contentTop)
	header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", contentRight, contentTop)
	header:SetHeight(PREVIEW_TOP + 28 + PREVIEW_BOTTOM)
	self.previewHeader = header
	local previewLabel = GoldLabel(header, "Preview", 16)
	previewLabel:SetPoint("TOPLEFT", 8, -8)
	local previewLine = header:CreateTexture(nil, "ARTWORK")
	previewLine:SetPoint("TOPLEFT", 8, -26)
	previewLine:SetSize(600, 1)
	ColorTex(previewLine, 1, 0.82, 0, 0.4)
	self.previewChecks = {}
	for n = 1, #DiveBar.FEATURE_LIST do
		local feature = DiveBar.FEATURE_LIST[n]
		local check = Check(header, DiveBar.FEATURE_LABEL[feature], function(value)
			DiveBar.previewShow[feature] = value
		end)
		check.Refresh = function()
			local on = DiveBar.profile[feature] and true or false
			check:SetChecked(on and DiveBar.previewShow[feature] ~= false)
			check:SetDimmed(not on)
		end
		self.previewChecks[feature] = check
	end
	local previewHolder = CreateFrame("Frame", nil, header)
	previewHolder:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -PREVIEW_TOP)
	previewHolder:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, -PREVIEW_TOP)
	previewHolder:SetHeight(28)
	self.previewHolder = previewHolder
	self.preview = self:BuildBar(nil, previewHolder, false)
	self.preview:SetPoint("TOP", previewHolder, "TOP", 0, -6)
	self.preview:Show()
	local previewEmpty = Cream(previewHolder, "Tick a bar above to preview it.")
	previewEmpty:SetPoint("CENTER")
	previewEmpty:Hide()
	self.previewEmptyText = previewEmpty
	local headerLine = header:CreateTexture(nil, "ARTWORK")
	headerLine:SetPoint("BOTTOMLEFT", 8, 0)
	headerLine:SetSize(600, 1)
	ColorTex(headerLine, 1, 0.82, 0, 0.4)

	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", contentRight, contentBottom)

	local body = CreateFrame("Frame", nil, content)
	body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
	body:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -4)
	body:SetHeight(1)
	self.optionsBody = body

	self.optionsContent = content
	self.UpdateOptionsScroll = UpdateScroll
	self:BuildOptionSections(body)
	self:LayoutOptions()
	UpdateScroll()
	panel:SetScript("OnShow", function()
		HideMenu()
		DiveBar:SyncOptions()
		DiveBar:Refresh()
		UpdateScroll()
	end)
	panel:SetScript("OnHide", HideMenu)

	if not StaticPopupDialogs.DIVEBAR_CONFIRM then
		StaticPopupDialogs.DIVEBAR_CONFIRM = {
			text = "%s",
			button1 = YES or "Yes",
			button2 = CANCEL or "Cancel",
			OnAccept = function(dialog)
				local data = dialog.data
				if data and data.fn then
					data.fn()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	panel:SetPoint("CENTER")
end

function DiveBar:ToggleOptions()
	if not self.options then
		return
	end
	if self.options:IsShown() then
		self.options:Hide()
	else
		self.options:Show()
	end
end

function DiveBar:CreateUI()
	if self.uiReady then
		return
	end
	self.uiReady = true
	self:CreateBars()
	self:CreateMinimap()
	self:CreateOptions()
	self:RegisterCombatEvents()
	self:EnsureCast()
	self:EnsureTimers()
end
