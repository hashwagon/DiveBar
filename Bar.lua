-- The single player frame. Rows stack in profile order and grow from the anchor.

DiveBar = DiveBar or {}

local function Color(texture, color)
	local r, g, b, a = color[1], color[2], color[3], color[4] or 1
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a)
	else
		texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		texture:SetVertexColor(r, g, b, a)
	end
end

local function Solid(parent, layer, sublayer)
	local texture = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublayer or 0)
	texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	return texture
end

local function Font(fs, size, color)
	local face = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	fs:SetFont(face, size, "")
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function Tint(texture, color)
	texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
end

local function UseSpark(texture)
	texture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	texture:SetBlendMode("ADD")
end

local BORDER_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"

local function BorderU(px)
	return px / 128
end

local function BorderV(px)
	return px / 16
end

-- Left-aligned slices keep the silver line on the low-U side. Right-aligned
-- slices keep it on the high-U side. turn puts that outside edge on the top
-- or bottom of a horizontal piece.
local function CropBorder(tex, left, right, top, bottom, turn)
	if turn then
		tex:SetTexCoord(BorderU(left), BorderV(top), BorderU(right), BorderV(top), BorderU(left), BorderV(bottom), BorderU(right), BorderV(bottom))
	else
		tex:SetTexCoord(BorderU(left), BorderU(right), BorderV(top), BorderV(bottom))
	end
end

local function MakeBorder(bar)
	local holder = CreateFrame("Frame", nil, bar)
	holder:SetAllPoints(bar)
	holder:EnableMouse(false)
	if holder.SetMouseClickEnabled then
		holder:SetMouseClickEnabled(false)
	end
	if holder.SetMouseMotionEnabled then
		holder:SetMouseMotionEnabled(false)
	end
	local function piece()
		local tex = holder:CreateTexture(nil, "OVERLAY", nil, 7)
		tex:SetTexture(BORDER_TEX)
		return tex
	end
	holder.tl = piece()
	holder.tr = piece()
	holder.bl = piece()
	holder.br = piece()
	holder.top = piece()
	holder.bottom = piece()
	holder.left = piece()
	holder.right = piece()
	-- Each slice is 16 texels. The line is the outer 6.
	CropBorder(holder.left, 0, 6, 0, 16, false)
	CropBorder(holder.right, 26, 32, 0, 16, false)
	CropBorder(holder.top, 32, 38, 0, 16, true)
	CropBorder(holder.bottom, 58, 64, 0, 16, true)
	CropBorder(holder.tl, 64, 70, 0, 6, false)
	CropBorder(holder.tr, 90, 96, 0, 6, false)
	CropBorder(holder.bl, 96, 102, 10, 16, false)
	CropBorder(holder.br, 122, 128, 10, 16, false)
	bar.border = holder
end

local function PlaceBorder(bar, thickness, rounded)
	local holder = bar.border
	local t = thickness
	if t < 1 then
		t = 1
	end
	local w = bar:GetWidth() or 0
	local h = bar:GetHeight() or 0
	if w > 2 and t * 2 > w then
		t = w / 2
	end
	if h > 2 and t * 2 > h then
		t = h / 2
	end
	holder:ClearAllPoints()
	holder:SetAllPoints(bar)
	local level = (bar:GetFrameLevel() or 0) + 20
	if holder:GetFrameLevel() ~= level then
		holder:SetFrameLevel(level)
	end
	local caps = { holder.tl, holder.tr, holder.bl, holder.br }
	for i = 1, #caps do
		caps[i]:SetShown(rounded and true or false)
	end
	if rounded then
		holder.tl:ClearAllPoints()
		holder.tl:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		holder.tl:SetSize(t, t)
		holder.tr:ClearAllPoints()
		holder.tr:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
		holder.tr:SetSize(t, t)
		holder.bl:ClearAllPoints()
		holder.bl:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
		holder.bl:SetSize(t, t)
		holder.br:ClearAllPoints()
		holder.br:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
		holder.br:SetSize(t, t)
		holder.top:ClearAllPoints()
		holder.top:SetPoint("TOPLEFT", holder.tl, "TOPRIGHT", 0, 0)
		holder.top:SetPoint("BOTTOMRIGHT", holder.tr, "BOTTOMLEFT", 0, 0)
		holder.bottom:ClearAllPoints()
		holder.bottom:SetPoint("TOPLEFT", holder.bl, "TOPRIGHT", 0, 0)
		holder.bottom:SetPoint("BOTTOMRIGHT", holder.br, "BOTTOMLEFT", 0, 0)
		holder.left:ClearAllPoints()
		holder.left:SetPoint("TOPLEFT", holder.tl, "BOTTOMLEFT", 0, 0)
		holder.left:SetPoint("BOTTOMRIGHT", holder.bl, "TOPRIGHT", 0, 0)
		holder.right:ClearAllPoints()
		holder.right:SetPoint("TOPLEFT", holder.tr, "BOTTOMLEFT", 0, 0)
		holder.right:SetPoint("BOTTOMRIGHT", holder.br, "TOPRIGHT", 0, 0)
	else
		holder.top:ClearAllPoints()
		holder.top:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		holder.top:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
		holder.top:SetHeight(t)
		holder.bottom:ClearAllPoints()
		holder.bottom:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
		holder.bottom:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
		holder.bottom:SetHeight(t)
		holder.left:ClearAllPoints()
		holder.left:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -t)
		holder.left:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, t)
		holder.left:SetWidth(t)
		holder.right:ClearAllPoints()
		holder.right:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -t)
		holder.right:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, t)
		holder.right:SetWidth(t)
	end
	holder:Show()
end

local function MakeRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row.bg = Solid(row, "BACKGROUND", 0)
	row.bg:SetAllPoints()
	row.top = Solid(row, "BORDER", 1)
	row.top:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	row.top:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
	row.top:SetHeight(1)
	row.bottom = Solid(row, "BORDER", 1)
	row.bottom:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	row.bottom:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
	row.bottom:SetHeight(1)
	row.trough = CreateFrame("Frame", nil, row)
	row.troughBG = row.trough:CreateTexture(nil, "BACKGROUND", nil, 0)
	row.troughBG:SetAllPoints()
	row.troughBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.troughTop = Solid(row.trough, "BACKGROUND", 1)
	row.troughTop:SetPoint("TOPLEFT", row.trough, "TOPLEFT", 0, 0)
	row.troughTop:SetPoint("TOPRIGHT", row.trough, "TOPRIGHT", 0, 0)
	row.troughTop:SetHeight(1)
	return row
end

local BADGE_FONT = "Fonts\\ARIALN.TTF"

local function LevelTimeFont(fs)
	fs:SetFont(BADGE_FONT, 10, "")
	fs:SetJustifyH("CENTER")
	fs:SetWordWrap(false)
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(0.95, 0.95, 0.95, 1)
end

-- The badge wears the frame's own tooltip rim, so the corners match the bar and follow Rounded corners.
local function MakeBadge(row)
	local badge = CreateFrame("Frame", nil, row)
	badge:EnableMouse(false)
	badge.fill = Solid(badge, "BACKGROUND", 0)
	Color(badge.fill, { 0.11, 0.11, 0.11, 0.95 })
	MakeBorder(badge)
	-- The rim draws on its own frame above the fill, so the number goes one level higher still.
	badge.top = CreateFrame("Frame", nil, badge)
	badge.top:SetAllPoints(badge)
	badge.top:EnableMouse(false)
	badge.label = badge.top:CreateFontString(nil, "OVERLAY")
	LevelTimeFont(badge.label)
	badge.label:SetPoint("CENTER", badge, "CENTER", 0, 0)
	badge:Hide()
	row.badge = badge
	row.levelOverlay = CreateFrame("Frame", nil, row)
	row.levelOverlay:SetAllPoints(row)
	row.levelOverlay:EnableMouse(false)
	row.levelText = row.levelOverlay:CreateFontString(nil, "OVERLAY")
	LevelTimeFont(row.levelText)
	row.levelText:Hide()
end

local function MakeFill(parent)
	local fill = CreateFrame("Frame", nil, parent)
	fill.bg = fill:CreateTexture(nil, "ARTWORK", nil, 1)
	fill.bg:SetAllPoints()
	fill.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	return fill
end

local function ToUI(region)
	local x, y = region:GetCenter()
	if not x or not y then
		return nil
	end
	local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return x * scale, y * scale
end

local function ToUIPoint(region, point)
	local x = region:GetCenter()
	local y
	if point == "TOP" then
		y = region:GetTop()
	elseif point == "BOTTOM" then
		y = region:GetBottom()
	else
		x, y = region:GetCenter()
	end
	if not x or not y then
		return nil
	end
	local scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return x * scale, y * scale
end

function DiveBar:CreateBars()
	if self.bar then
		return
	end
	self.bar = self:BuildBar("DiveBarFrame", UIParent, true)
	self.bar:SetFrameStrata("MEDIUM")
	self.bar:SetClampedToScreen(true)
	self.bar:SetMovable(true)
	self.bar:EnableMouse(true)
	self.bar:RegisterForDrag("LeftButton")
	self.bar:SetScript("OnDragStart", function(bar)
		if DiveBar.profile.lock or DiveBar.dragging then
			return
		end
		DiveBar.dragging = true
		bar:StartMoving()
	end)
	self.bar:SetScript("OnDragStop", function(bar)
		bar:StopMovingOrSizing()
		DiveBar.dragging = false
		DiveBar:SaveAnchor()
	end)
	self:CreateLockButton(self.bar)
end

-- First-run mover control. Later unlocks drag the bar and do not bring this back.
function DiveBar:CreateLockButton(bar)
	local button
	local ok, created = pcall(CreateFrame, "Button", "DiveBarLockButton", bar, "UIPanelDynamicResizeButtonTemplate")
	if (not ok or not created) then
		ok, created = pcall(CreateFrame, "Button", "DiveBarLockButton", bar, "UIPanelButtonTemplate")
	end
	if ok and created then
		button = created
		button:SetText("Lock")
		if DynamicResizeButton_Resize then
			DynamicResizeButton_Resize(button)
		else
			button:SetSize(64, 22)
		end
	else
		button = CreateFrame("Button", "DiveBarLockButton", bar)
		button:SetSize(64, 22)
		button:SetNormalFontObject(GameFontNormal)
		button:SetText("Lock")
	end
	button:Hide()
	button:RegisterForClicks("LeftButtonUp")
	button:SetFrameStrata("HIGH")
	button:SetScript("OnEnter", function()
		if GameTooltip then
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Lock", 1, 0.824, 0)
			GameTooltip:AddLine("Lock the bar in place.", 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnClick", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
		DiveBar:SetLocked(true)
		DiveBar:Refresh()
		if DiveBar.SyncOptions then
			DiveBar:SyncOptions()
		end
		DiveBar:Print("Locked.")
	end)
	bar.lockButton = button
end

function DiveBar:UpdateLockButton()
	local bar = self.bar
	local button = bar and bar.lockButton
	if not button then
		return
	end
	local show = bar:IsShown() and self.profile and self.FirstRun(self.profile)
	button:SetShown(show and true or false)
	if not show then
		return
	end
	button:SetFrameStrata("HIGH")
	button:SetFrameLevel((bar:GetFrameLevel() or 0) + 40)
	button:ClearAllPoints()
	local top = bar:GetTop()
	local screen = UIParent and UIParent:GetTop()
	local barScale = bar:GetEffectiveScale() or 1
	local screenScale = UIParent and UIParent:GetEffectiveScale() or 1
	local nearTop = top and screen and (screen * screenScale - top * barScale) < 24
	if nearTop then
		button:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -4, -4)
	else
		button:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -4, 0)
	end
end

function DiveBar:BuildBar(globalName, parent, interactive)
	local ok, created = pcall(CreateFrame, "Frame", globalName, parent, "BackdropTemplate")
	local bar = (ok and created) or CreateFrame("Frame", globalName, parent)
	bar.interactive = interactive
	bar.chrome = {}
	local chrome = bar.chrome
	chrome.metal = Solid(bar, "BACKGROUND", 0)
	chrome.metal:SetPoint("TOPLEFT", 1, -1)
	chrome.metal:SetPoint("BOTTOMRIGHT", -1, 1)
	chrome.top = Solid(bar, "BORDER", 1)
	chrome.top:SetPoint("TOPLEFT", 1, -1)
	chrome.top:SetPoint("TOPRIGHT", -1, -1)
	chrome.top:SetHeight(2)
	chrome.bottom = Solid(bar, "BORDER", 1)
	chrome.bottom:SetPoint("BOTTOMLEFT", 1, 1)
	chrome.bottom:SetPoint("BOTTOMRIGHT", -1, 1)
	chrome.bottom:SetHeight(2)
	chrome.left = Solid(bar, "BORDER", 1)
	chrome.left:SetPoint("TOPLEFT", 1, -1)
	chrome.left:SetPoint("BOTTOMLEFT", 1, 1)
	chrome.left:SetWidth(2)
	chrome.right = Solid(bar, "BORDER", 1)
	chrome.right:SetPoint("TOPRIGHT", -1, -1)
	chrome.right:SetPoint("BOTTOMRIGHT", -1, 1)
	chrome.right:SetWidth(2)

	bar.inner = CreateFrame("Frame", nil, bar)
	bar.inner:EnableMouse(false)
	bar.innerBG = Solid(bar.inner, "BACKGROUND", 0)
	bar.innerBG:SetAllPoints()
	local edgeOk, edgeFrame = pcall(CreateFrame, "Frame", nil, bar, "BackdropTemplate")
	if edgeOk and edgeFrame then
		edgeFrame:SetAllPoints(bar)
		edgeFrame:EnableMouse(false)
		bar.edgeFrame = edgeFrame
	end

	bar.cast = MakeRow(bar.inner)
	bar.cast.icon = CreateFrame("Frame", nil, bar.cast)
	bar.cast.iconTex = bar.cast.icon:CreateTexture(nil, "ARTWORK")
	bar.cast.iconTex:SetAllPoints()
	bar.cast.iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	bar.cast.fill = MakeFill(bar.cast.trough)
	bar.cast.lat = Solid(bar.cast.fill, "ARTWORK", 3)
	-- Child frames draw above the parent's font strings, so the name sits on its own frame.
	bar.cast.overlay = CreateFrame("Frame", nil, bar.cast.trough)
	bar.cast.overlay:SetAllPoints(bar.cast.trough)
	bar.cast.overlay:EnableMouse(false)
	if bar.cast.overlay.SetClipsChildren then
		bar.cast.overlay:SetClipsChildren(true)
	end
	bar.cast.spark = bar.cast.overlay:CreateTexture(nil, "OVERLAY", nil, 4)
	UseSpark(bar.cast.spark)
	bar.cast.spark:Hide()
	bar.cast.name = bar.cast.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.cast.name:SetJustifyH("LEFT")
	bar.cast.name:SetWordWrap(false)
	bar.cast.nameBG = Solid(bar.cast.overlay, "ARTWORK", 1)
	bar.cast.time = bar.cast.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.cast.time:SetJustifyH("RIGHT")
	bar.cast.time:SetWordWrap(false)
	bar.cast.name:SetPoint("LEFT", bar.cast.overlay, "LEFT", 6, 0)
	bar.cast.time:SetPoint("RIGHT", bar.cast.overlay, "RIGHT", -6, 0)
	bar.cast.nameBG:SetPoint("CENTER", bar.cast.name, "CENTER", 0, 0)

	bar.swing = {}
	local keys = { "melee", "off", "shot", "wand" }
	for i = 1, #keys do
		local row = MakeRow(bar.inner)
		row.fill = MakeFill(row.trough)
		if row.trough.SetClipsChildren then
			row.trough:SetClipsChildren(true)
		end
		row.spark = row.trough:CreateTexture(nil, "OVERLAY", nil, 4)
		UseSpark(row.spark)
		row.spark:Hide()
		row:Hide()
		bar.swing[keys[i]] = row
	end

	bar.timer = {}
	for i = 1, 3 do
		local row = MakeRow(bar.inner)
		row.fill = MakeFill(row.trough)
		row.overlay = CreateFrame("Frame", nil, row.trough)
		row.overlay:SetAllPoints(row.trough)
		row.overlay:EnableMouse(false)
		row.label = row.overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.label:SetJustifyH("LEFT")
		row.label:SetWordWrap(false)
		row.label:SetPoint("LEFT", row.overlay, "LEFT", 6, 0)
		row.time = row.overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.time:SetJustifyH("RIGHT")
		row.time:SetWordWrap(false)
		row.time:SetPoint("RIGHT", row.overlay, "RIGHT", -6, 0)
		row:Hide()
		bar.timer[i] = row
	end

	bar.pinMark = CreateFrame("Frame", nil, bar)
	bar.pinMark:SetSize(1, 1)
	bar.pinMark:EnableMouse(false)
	if bar.pinMark.SetMouseClickEnabled then
		bar.pinMark:SetMouseClickEnabled(false)
	end

	bar.xp = MakeRow(bar.inner)
	bar.xp.current = MakeFill(bar.xp.trough)
	bar.xp.rested = MakeFill(bar.xp.trough)
	bar.xp.quest = MakeFill(bar.xp.trough)
	MakeBadge(bar.xp)
	bar.xp:Hide()
	MakeBorder(bar)
	bar:Hide()
	if interactive and self.BindXPTooltip then
		self:BindXPTooltip(bar)
	end
	return bar
end

function DiveBar:ApplyEdge(bar, theme)
	if bar.edgeFrame then
		bar.edgeFrame:Hide()
	end
	local chrome = bar.chrome
	chrome.metal:Hide()
	chrome.top:Hide()
	chrome.bottom:Hide()
	chrome.left:Hide()
	chrome.right:Hide()
	if bar.ClearBackdrop then
		pcall(bar.ClearBackdrop, bar)
	elseif bar.SetBackdrop then
		pcall(bar.SetBackdrop, bar, nil)
	end
	if not bar.border then
		MakeBorder(bar)
	end
	-- Thickness follows the slider. The piece is only the gold line, so a
	-- short experience frame does not have to shrink every setting to one size.
	local thickness = bar._fitRim or theme.rim or DiveBar.BorderThickness(theme.borderSize)
	local rounded = not (self.profile and self.profile.roundedCorners == false)
	PlaceBorder(bar, thickness, rounded)
	local r, g, b = 1, 1, 1
	if theme.flatBorder then
		r, g, b = 0.7, 0.7, 0.7
	end
	local holder = bar.border
	local parts = { holder.tl, holder.tr, holder.bl, holder.br, holder.top, holder.bottom, holder.left, holder.right }
	for i = 1, #parts do
		parts[i]:SetVertexColor(r, g, b, 1)
	end
end

function DiveBar:ApplyColors(bar, theme)
	Color(bar.innerBG, theme.background or { 0.02, 0.02, 0.02, 0.95 })
	bar.innerBG:Show()
	self:ApplyEdge(bar, theme)

	local function paintRow(row)
		row.bg:Hide()
		row.top:Hide()
		row.bottom:Hide()
		row.troughBG:SetTexture("Interface\\Buttons\\WHITE8X8")
		Tint(row.troughBG, theme.empty or { 0.08, 0.08, 0.08 })
		row.troughTop:Hide()
	end
	paintRow(bar.cast)
	Color(bar.cast.lat, theme.latency)
	Color(bar.cast.nameBG, theme.nameBG)
	Font(bar.cast.name, self.profile.textSize, theme.text)
	Font(bar.cast.time, self.profile.textSize, theme.text)

	for _, row in pairs(bar.swing) do
		paintRow(row)
	end
	for i = 1, #bar.timer do
		local row = bar.timer[i]
		paintRow(row)
		Font(row.label, self.profile.textSize, theme.text)
		Font(row.time, self.profile.textSize, theme.text)
	end
	paintRow(bar.xp)
end

function DiveBar:ResolveChrome(contentH, theme)
	return DiveBar.FitChrome(contentH, theme.borderSize, theme.rim, self.profile.roundedCorners ~= false)
end

-- What the frame adds on each side of the Width setting: the border inset.
function DiveBar:ChromeSide(profile, theme)
	return DiveBar.ContentInset(theme.rim, profile.roundedCorners ~= false)
end

function DiveBar:BlockRow(bar, block)
	if block.kind == "cast" then
		return bar.cast
	end
	if block.kind == "xp" then
		return bar.xp
	end
	if block.kind == "timer" then
		return bar.timer[block.slot]
	end
	return bar.swing[block.key]
end

function DiveBar:MarkAnchor(bar, blocks, profile)
	local mark = bar.pinMark
	local order = self.OrderedFeatures(profile)
	local mode, index = self.AnchorMeasure(blocks, order, self.NormalizeAnchor(profile))
	mark:ClearAllPoints()
	if not mode then
		mark:SetPoint("CENTER", bar, "CENTER", 0, 0)
		mark:SetSize(1, 1)
		return
	end
	if mode == "center" then
		local feature = blocks[index].feature
		local first
		local last
		for i = 1, #blocks do
			if blocks[i].feature == feature then
				local row = self:BlockRow(bar, blocks[i])
				if not first then
					first = row
				end
				last = row
			end
		end
		mark:SetPoint("TOPLEFT", first, "TOPLEFT", 0, 0)
		mark:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 0, 0)
		return
	end
	local row = self:BlockRow(bar, blocks[index])
	if mode == "top" then
		mark:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 0, 0)
		mark:SetPoint("BOTTOMRIGHT", row, "TOPRIGHT", 0, 0)
	else
		mark:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, 0)
		mark:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, 0)
	end
	mark:SetHeight(1)
end

function DiveBar:Place(bar, state, theme, profile, width)
	local spec = {
		cast = state.showCast and true or false,
		xp = state.xp and true or false,
		swings = state.swings or {},
		timers = state.timers or {},
	}
	local blocks = self.Blocks(profile, spec)
	local margin = profile.margin or 0
	local contentH = self.ContentHeight(blocks) + margin * 2
	if contentH < 1 then
		contentH = 1
	end
	local line, inset, frameH = self:ResolveChrome(contentH, theme)
	bar._fitRim = line
	-- The chrome hugs whatever is actually on screen. The background starts
	-- under the border line, and the rounded corner covers its square corners.
	-- Margin and padding are vertical only, so the bars run into the side border.
	bar:SetSize(width + inset * 2, frameH)
	bar.inner:ClearAllPoints()
	bar.inner:SetPoint("TOPLEFT", bar, "TOPLEFT", inset, -inset)
	bar.inner:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -inset, inset)

	bar.cast:Hide()
	for _, row in pairs(bar.swing) do
		row:Hide()
	end
	for i = 1, #bar.timer do
		bar.timer[i]:Hide()
	end
	bar.xp:Hide()

	local top = margin
	for i = 1, #blocks do
		local block = blocks[i]
		local row = self:BlockRow(bar, block)
		row:Show()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", bar.inner, "TOPLEFT", 0, -top)
		row:SetPoint("TOPRIGHT", bar.inner, "TOPRIGHT", 0, -top)
		row:SetHeight(block.h)
		if block.kind == "cast" then
			self:PlaceCastRow(bar, state, theme, block)
		else
			row.trough:ClearAllPoints()
			row.trough:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -block.pad)
			row.trough:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, block.pad)
		end
		top = top + block.h
	end
	self:MarkAnchor(bar, blocks, profile)
	self:ApplyEdge(bar, theme)
end

function DiveBar:PlaceCastRow(bar, state, theme, block)
	local cast = bar.cast
	local pad = block.pad
	local showIcon = state.showIcon and state.icon and state.mode ~= "idle"
	cast.icon:SetShown(showIcon and true or false)
	cast.trough:ClearAllPoints()
	cast.trough:SetPoint("TOPRIGHT", cast, "TOPRIGHT", 0, -pad)
	cast.trough:SetPoint("BOTTOMRIGHT", cast, "BOTTOMRIGHT", 0, pad)
	if showIcon then
		cast.icon:ClearAllPoints()
		cast.icon:SetPoint("LEFT", cast, "LEFT", 0, 0)
		cast.icon:SetSize(block.barH, block.barH)
		cast.trough:SetPoint("TOPLEFT", cast.icon, "TOPRIGHT", theme.gap, 0)
		if state.icon then
			cast.iconTex:SetTexture(state.icon)
		end
		local desat = state.mode == "interrupt"
		if cast.iconTex.SetDesaturated then
			cast.iconTex:SetDesaturated(desat)
		end
		if desat then
			cast.iconTex:SetVertexColor(0.55, 0.55, 0.55)
		else
			cast.iconTex:SetVertexColor(1, 1, 1)
		end
	else
		cast.trough:SetPoint("TOPLEFT", cast, "TOPLEFT", 0, -pad)
	end
end

local function AnchorFill(fill, trough, fraction, alignRight, width)
	fraction = fraction or 0
	if fraction < 0 then
		fraction = 0
	elseif fraction > 1 then
		fraction = 1
	end
	local pixels = width * fraction
	if pixels > 0 and pixels < 1 then
		pixels = 1
	end
	fill:ClearAllPoints()
	if alignRight then
		fill:SetPoint("TOPRIGHT", trough, "TOPRIGHT", 0, 0)
		fill:SetPoint("BOTTOMRIGHT", trough, "BOTTOMRIGHT", 0, 0)
	else
		fill:SetPoint("TOPLEFT", trough, "TOPLEFT", 0, 0)
		fill:SetPoint("BOTTOMLEFT", trough, "BOTTOMLEFT", 0, 0)
	end
	fill:SetWidth(math.max(0, pixels))
	fill:SetShown(pixels > 0)
	return pixels
end

local function PlaceSegment(fill, trough, offset, pixels)
	if offset < 0 then
		offset = 0
	end
	if pixels > 0 and pixels < 1 then
		pixels = 1
	end
	fill:ClearAllPoints()
	fill:SetPoint("TOPLEFT", trough, "TOPLEFT", offset, 0)
	fill:SetPoint("BOTTOMLEFT", trough, "BOTTOMLEFT", offset, 0)
	fill:SetWidth(math.max(0, pixels))
	fill:SetShown(pixels > 0)
end

local function PlaceSpark(spark, fill, trough, shown)
	spark:ClearAllPoints()
	spark:SetPoint("CENTER", fill, "RIGHT", 0, 0)
	local height = trough:GetHeight()
	if not height or height < 4 then
		height = 8
	end
	-- Blizzard's spark is a vertical glint on the leading edge. Match the row so it stays inside the bar.
	spark:SetSize(math.max(16, math.min(28, height * 1.75)), height)
	spark:SetShown(shown and true or false)
end

function DiveBar:Paint(bar, state, theme, profile, width)
	local cast = bar.cast
	local innerW = width
	local showIcon = state.showIcon and state.icon and state.mode ~= "idle"
	local iconSpace = showIcon and (profile.castHeight + theme.gap) or 0
	local troughW = innerW - iconSpace
	if troughW < 8 then
		troughW = 8
	end

	local mode = state.mode or "idle"
	local fraction = state.progress or 0
	if mode == "interrupt" then
		fraction = 1
	elseif mode == "idle" then
		fraction = 0
	end

	local fillColor
	if mode == "channel" then
		fillColor = theme.channel
	elseif mode == "interrupt" then
		fillColor = theme.interrupt
	else
		fillColor = theme.cast
	end
	local baseLevel = cast.trough:GetFrameLevel()
	cast.fill:SetFrameLevel(baseLevel + 1)
	cast.overlay:SetFrameLevel(baseLevel + 5)
	Tint(cast.fill.bg, fillColor)
	-- Casts grow to the right. Channels keep the filled part on the left and shrink right to left.
	local filled = AnchorFill(cast.fill, cast.trough, fraction, false, troughW)

	local showLatency = state.showLatency and mode == "cast" and filled > 4 and (state.latency or 0) > 0
	cast.lat:ClearAllPoints()
	cast.lat:SetPoint("TOPRIGHT", cast.fill, "TOPRIGHT", 0, 0)
	cast.lat:SetPoint("BOTTOMRIGHT", cast.fill, "BOTTOMRIGHT", 0, 0)
	local latW = math.min(filled, math.max(2, troughW * (state.latency or 0)))
	cast.lat:SetWidth(latW)
	cast.lat:SetShown(showLatency)

	PlaceSpark(cast.spark, cast.fill, cast.trough, mode ~= "idle" and mode ~= "interrupt" and fraction > 0.01 and fraction < 0.995)

	local label = ""
	if mode == "interrupt" then
		label = "Interrupted"
	elseif mode ~= "idle" and state.showName then
		label = state.name or ""
	end
	if label ~= "" then
		cast.name:Show()
		cast.name:SetText(label)
		if theme.namePlate then
			cast.nameBG:Show()
			cast.nameBG:SetSize(cast.name:GetStringWidth() + 8, cast.name:GetStringHeight() + 3)
		else
			cast.nameBG:Hide()
		end
	else
		cast.name:Hide()
		cast.nameBG:Hide()
	end

	if state.showTime and (mode == "cast" or mode == "channel") and (state.total or 0) > 0 then
		cast.time:Show()
		cast.time:SetText(string.format("%.1f / %.1f", math.max(0, state.remain or 0), state.total or 0))
	else
		cast.time:Hide()
		cast.time:SetText("")
	end

	local swingInner = innerW
	local function chosen(key, fallback)
		local color = profile.colors and profile.colors[key]
		if type(color) == "table" and tonumber(color[1]) then
			return color
		end
		return fallback
	end
	local meleeColor = chosen("melee", { theme.melee[1], theme.melee[2], theme.melee[3] })
	local offColor = chosen("off", { theme.off[1], theme.off[2], theme.off[3] })
	local shotColor = chosen("shot", { theme.steel[1], theme.steel[2], theme.steel[3] })
	local wandColor = chosen("wand", shotColor)
	local swingColors = {
		melee = meleeColor,
		off = offColor,
		shot = shotColor,
		wand = wandColor,
	}
	local progress = state.progressSwing or {}
	for key, row in pairs(bar.swing) do
		if row:IsShown() then
			Tint(row.fill.bg, swingColors[key])
			local amount = progress[key] or 0
			local pixels = AnchorFill(row.fill, row.trough, amount, false, swingInner)
			PlaceSpark(row.spark, row.fill, row.trough, pixels > 1 and amount < 0.995)
		end
	end

	local timerInner = innerW
	local timerColors = self.TIMER_COLOR or {}
	local timerMeta = state.timerMeta or {}
	local timerProgress = state.timerProgress or {}
	for i = 1, #bar.timer do
		local row = bar.timer[i]
		if row:IsShown() then
			local key
			local timers = state.timers or {}
			key = timers[i]
			local meta = key and timerMeta[key] or {}
			local color = timerColors[key] or { 0.45, 0.45, 0.45 }
			Tint(row.fill.bg, color)
			local amount = key and timerProgress[key] or 0
			AnchorFill(row.fill, row.trough, amount, false, timerInner)
			local label = meta.label or ""
			if label ~= "" then
				row.label:Show()
				row.label:SetText(label)
			else
				row.label:Hide()
				row.label:SetText("")
			end
			local remain = tonumber(meta.value)
			if remain and remain >= 0 and key ~= "idle" then
				local whole = math.floor(remain + 0.5)
				row.time:SetText(string.format("%d:%02d", math.floor(whole / 60), whole % 60))
				row.time:Show()
			else
				row.time:Hide()
				row.time:SetText("")
			end
		end
	end

	if bar.xp:IsShown() and state.xp then
		Tint(bar.xp.current.bg, self.XP_COLOR)
		Tint(bar.xp.rested.bg, self.RESTED_COLOR)
		Tint(bar.xp.quest.bg, self.QUEST_COLOR or { 1, 0.82, 0 })
		local value = state.xp.value or 0
		if value < 0 then
			value = 0
		elseif value > 1 then
			value = 1
		end
		local rested = state.xp.rested or 0
		local quest = state.xp.quest or 0
		local restedFit = self.XPSegment(value, rested)
		local questFit = self.XPSegment(value, quest)
		local base = bar.xp.trough:GetFrameLevel() or 0
		bar.xp.current:SetFrameLevel(base + 1)
		-- The shorter extension is the one you can still see the end of.
		if self.XPOverlayTop(rested, quest) == "quest" then
			bar.xp.rested:SetFrameLevel(base + 2)
			bar.xp.quest:SetFrameLevel(base + 3)
		else
			bar.xp.quest:SetFrameLevel(base + 2)
			bar.xp.rested:SetFrameLevel(base + 3)
		end
		if bar.xp.hover and bar.xp.hover.SetFrameLevel then
			bar.xp.hover:SetFrameLevel(base + 6)
		end
		local currentW = AnchorFill(bar.xp.current, bar.xp.trough, value, false, swingInner)
		PlaceSegment(bar.xp.rested, bar.xp.trough, currentW, swingInner * restedFit)
		PlaceSegment(bar.xp.quest, bar.xp.trough, currentW, swingInner * questFit)
		self:PaintLevelTime(bar, bar.xp, state.xpBadge, currentW, swingInner, profile, theme, base + 4)
	end
end

-- A font without the infinity glyph draws nothing, so a zero width means use the fallback.
local function SetLevelText(fs, text, size, flags)
	if text ~= DiveBar.NO_RATE_TEXT then
		fs:SetFont(BADGE_FONT, size, flags)
		fs:SetText(text)
		return
	end
	fs:SetFont(BADGE_FONT, size * DiveBar.NO_RATE_SCALE, flags)
	fs:SetText(text)
	if (fs:GetStringWidth() or 0) < 1 then
		fs:SetFont(BADGE_FONT, size, flags)
		fs:SetText(DiveBar.NO_RATE_FALLBACK)
	end
end

function DiveBar:PaintLevelTime(bar, row, text, filled, troughW, profile, theme, level)
	row.badgeText = text
	local badge = row.badge
	local label = row.levelText
	if not badge or not label then
		return
	end
	local style = profile.xpLevelTime
	local size = profile.xpLevelTimeSize or 10
	if not text or style == "off" then
		badge:Hide()
		label:Hide()
		return
	end
	if style == "text" then
		badge:Hide()
		row.levelOverlay:SetFrameLevel(level)
		SetLevelText(label, text, size, "OUTLINE")
		local pad = 3
		local width = math.ceil(label:GetStringWidth() or 0) + pad * 2
		label:ClearAllPoints()
		label:SetPoint("LEFT", row.trough, "LEFT", self.XPBadgeOffset(filled, width, troughW) + pad, 0)
		label:Show()
		return
	end
	label:Hide()
	local font, rim, padX, height = self.XPBadgeSize(size, bar._fitRim or theme.rim)
	SetLevelText(badge.label, text, font, "")
	local width = math.ceil(badge.label:GetStringWidth() or 0) + padX * 2
	local badgeLevel = (bar:GetFrameLevel() or 0) + 21
	local rounded = profile.roundedCorners ~= false
	badge:SetFrameLevel(badgeLevel)
	badge:SetSize(width, height)
	badge:ClearAllPoints()
	badge:SetPoint("LEFT", row.trough, "LEFT", self.XPBadgeOffset(filled, width, troughW, rim * self.BORDER_SHADOW), 0)
	local inset = self.ContentInset(rim, rounded)
	badge.fill:ClearAllPoints()
	badge.fill:SetPoint("TOPLEFT", badge, "TOPLEFT", inset, -inset)
	badge.fill:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -inset, inset)
	PlaceBorder(badge, rim, rounded)
	local shade = theme.flatBorder and 0.7 or 0.85
	local holder = badge.border
	local parts = { holder.tl, holder.tr, holder.bl, holder.br, holder.top, holder.bottom, holder.left, holder.right }
	for i = 1, #parts do
		parts[i]:SetVertexColor(shade, shade, shade, 1)
	end
	badge.top:SetFrameLevel(badgeLevel + 21)
	badge:Show()
end

function DiveBar:SaveAnchor()
	local bar = self.bar
	if not bar or not self.profile or not bar.pinMark then
		return
	end
	local x, y = ToUI(bar.pinMark)
	if not x then
		return
	end
	self.profile.anchorX = x
	self.profile.anchorY = y
	self.profile.anchorPoint = "center"
end

function DiveBar:Pin(bar)
	if bar ~= self.bar or self.dragging then
		return
	end
	local profile = self.profile
	local mark = bar.pinMark or bar
	-- Older saves stored the cast row's bottom-left. Keep that spot, then remember the anchor center.
	if profile.anchorPoint ~= "center" and profile.anchorX and profile.anchor == "cast" and bar.cast:IsShown() then
		if not bar.cast:GetLeft() then
			bar:ClearAllPoints()
			bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", profile.anchorX, profile.anchorY)
		end
		local cx, cy = ToUI(bar.cast)
		if cx then
			profile.anchorX, profile.anchorY = cx, cy
			profile.anchorPoint = "center"
		end
		return
	end
	profile.anchorPoint = "center"
	local function measure()
		return ToUI(mark)
	end
	local x, y = measure()
	if not x then
		bar:ClearAllPoints()
		if profile.anchorX and profile.anchorY then
			bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", profile.anchorX, profile.anchorY)
		else
			bar:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
		end
		x, y = measure()
		if not x then
			return
		end
	end
	if not profile.anchorX then
		profile.anchorX, profile.anchorY = x, y
		return
	end
	local dx = profile.anchorX - x
	local dy = profile.anchorY - y
	if math.abs(dx) < 0.25 and math.abs(dy) < 0.25 then
		return
	end
	local frameX, frameY = ToUI(bar)
	if not frameX then
		return
	end
	bar:ClearAllPoints()
	bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", frameX + dx, frameY + dy)
end

function DiveBar:ApplyInteraction()
	local bar = self.bar
	if not bar then
		return
	end
	local locked = self.profile.lock
	bar:EnableMouse(not locked)
	bar:SetMovable(not locked)
	self:UpdateLockButton()
end

function DiveBar:Present(bar, state, opts)
	opts = opts or {}
	local profile = self.profile
	local theme = self:Theme()
	local width = opts.width or profile.width
	if not opts.preview then
		bar:SetScale(self.profile.scale or 1)
		bar:SetAlpha(self.profile.opacity or 1)
	end
	self:ApplyColors(bar, theme)
	local watchHover = bar == self.bar
	if watchHover then
		-- Place hides the experience row and shows it again. That hide must not drop the tooltip.
		self.keepXPTooltip = true
	end
	self:Place(bar, state, theme, profile, width)
	if watchHover then
		self.keepXPTooltip = false
	end
	self:Paint(bar, state, theme, profile, width)
	if not opts.preview then
		self.layoutKey = self:LayoutKey(state)
	end
	local showing = state.showCast or #(state.swings or {}) > 0 or #(state.timers or {}) > 0 or state.xp
	if bar == self.bar and self.playerReady and showing then
		-- Show before measuring. A hidden frame reports no position, so the anchor never stuck.
		bar:Show()
	end
	if opts.anchor then
		local signature = string.format(
			"%s:%s:%s:%s:%s",
			bar:GetWidth() or 0,
			bar:GetHeight() or 0,
			self.profile.scale or 1,
			self.profile.anchor or "",
			self:LayoutKey(state)
		)
		if signature ~= bar.pinSignature or not self.profile.anchorX then
			self:Pin(bar)
			if bar:GetCenter() then
				bar.pinSignature = signature
			end
		end
	end
	if bar == self.bar and self.playerReady then
		if showing then
			bar:Show()
			self:ApplyInteraction()
		else
			bar:Hide()
			self:UpdateLockButton()
		end
	end
	if bar == self.bar and self.SyncXPTooltip then
		self:SyncXPTooltip()
	end
end

function DiveBar:Refresh()
	if self.refreshing or not self.bar or not self.profile then
		return
	end
	self.refreshing = true
	self.OpenIntro(self.profile)
	self:Present(self.bar, self:BuildState(), { anchor = true })
	if self.preview then
		local previewWidth = self.profile.width
		local limit = 620
		if self.previewHolder and self.previewHolder:GetWidth() and self.previewHolder:GetWidth() > 80 then
			limit = self.previewHolder:GetWidth() - 8
		end
		limit = limit - self:ChromeSide(self.profile, self:Theme()) * 2
		if previewWidth > limit then
			previewWidth = limit
		end
		self:Present(self.preview, self:SampleState(), { width = previewWidth, preview = true })
		if self.FitPreview then
			self:FitPreview()
		end
	end
	if self.SyncOptions and self.options and self.options:IsShown() then
		self:SyncOptions()
	end
	self.refreshing = false
end
