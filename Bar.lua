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

-- A left-to-right alpha ramp: transparent on the left, `color` at `alpha` on the
-- right. Used for the badge marker's glow, which only ever bleeds to the left.
local function HGlow(texture, color, alpha)
	local r, g, b = color[1], color[2], color[3]
	texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	texture:SetVertexColor(1, 1, 1, 1)
	if texture.SetGradient and type(CreateColor) == "function" then
		if pcall(texture.SetGradient, texture, "HORIZONTAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, alpha)) then
			return
		end
	end
	if texture.SetGradientAlpha then
		if pcall(texture.SetGradientAlpha, texture, "HORIZONTAL", r, g, b, 0, r, g, b, alpha) then
			return
		end
	end
	texture:SetVertexColor(r, g, b, alpha * 0.6)
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

local function CropTooltip(holder)
	-- Each slice is 16 texels. The line is the outer 6.
	CropBorder(holder.left, 0, 6, 0, 16, false)
	CropBorder(holder.right, 26, 32, 0, 16, false)
	CropBorder(holder.top, 32, 38, 0, 16, true)
	CropBorder(holder.bottom, 58, 64, 0, 16, true)
	CropBorder(holder.tl, 64, 70, 0, 6, false)
	CropBorder(holder.tr, 90, 96, 0, 6, false)
	CropBorder(holder.bl, 96, 102, 10, 16, false)
	CropBorder(holder.br, 122, 128, 10, 16, false)
end

-- WoW Forever draws its window rims from this nine-slice in its own bronze art.
local METAL_ATLAS = {
	tl = "UI-Frame-Metal-CornerTopLeft",
	tr = "UI-Frame-Metal-CornerTopRight",
	bl = "UI-Frame-Metal-CornerBottomLeft",
	br = "UI-Frame-Metal-CornerBottomRight",
	top = "_UI-Frame-Metal-EdgeTop",
	bottom = "_UI-Frame-Metal-EdgeBottom",
	left = "!UI-Frame-Metal-EdgeLeft",
	right = "!UI-Frame-Metal-EdgeRight",
}
-- In atlas units, measured on Forever's art: the rim's outer edge sits this far
-- in from each piece's left, right, top and bottom side, and the rim with its
-- dark inner line is METAL_BAND deep. Only that band is drawn.
local METAL_L, METAL_R, METAL_T, METAL_B, METAL_BAND = 12.5, 2.5, 13, 7.5, 6

local metalArt
function DiveBar.MetalArt()
	if metalArt ~= nil then
		return metalArt
	end
	metalArt = false
	-- Other clients ship this atlas in their own metal, cut to other margins.
	if not (WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT) then
		return false
	end
	if not (C_Texture and C_Texture.GetAtlasInfo) then
		return false
	end
	local found = {}
	for key, name in pairs(METAL_ATLAS) do
		local info = C_Texture.GetAtlasInfo(name)
		if not info or not (info.file or info.filename) or (info.width or 0) <= 0 or (info.height or 0) <= 0 then
			return false
		end
		found[key] = info
	end
	metalArt = found
	return found
end

local function CropAtlas(tex, info, x1, x2, y1, y2)
	local L, T = info.leftTexCoord, info.topTexCoord
	local W, H = info.rightTexCoord - L, info.bottomTexCoord - T
	tex:SetTexCoord(L + W * x1 / info.width, L + W * x2 / info.width, T + H * y1 / info.height, T + H * y2 / info.height)
end

local function BorderParts(holder)
	return { holder.tl, holder.tr, holder.bl, holder.br, holder.top, holder.bottom, holder.left, holder.right }
end

-- The edges repeat along their length at the rim's scale, as Blizzard's windows
-- draw them, so a long frame does not smear the metal.
local function TileMetal(holder)
	local art = holder.skin == "metal" and DiveBar.MetalArt()
	local size = holder.size or 0
	if not art or size <= 0 then
		return
	end
	local scale = size / METAL_BAND
	local band = METAL_BAND
	local across = math.max((holder:GetWidth() or 0) - size * 2, 0) / scale
	local down = math.max((holder:GetHeight() or 0) - size * 2, 0) / scale
	local i = art.top
	CropAtlas(holder.top, i, 0, i.tilesHorizontally and across or i.width, METAL_T, METAL_T + band)
	i = art.bottom
	CropAtlas(holder.bottom, i, 0, i.tilesHorizontally and across or i.width, i.height - METAL_B - band, i.height - METAL_B)
	i = art.left
	CropAtlas(holder.left, i, METAL_L, METAL_L + band, 0, i.tilesVertically and down or i.height)
	i = art.right
	CropAtlas(holder.right, i, i.width - METAL_R - band, i.width - METAL_R, 0, i.tilesVertically and down or i.height)
end

-- "metal" is Forever's window rim, "solid" a plain band of the same depth, and
-- "tooltip" the tooltip line, where the client has no metal.
local function SkinBorder(holder, skin)
	if skin == "metal" and not DiveBar.MetalArt() then
		skin = "tooltip"
	elseif skin ~= "metal" and skin ~= "solid" then
		skin = "tooltip"
	end
	if holder.skin == skin then
		return
	end
	holder.skin = skin
	holder.band = skin ~= "tooltip"
	local parts = BorderParts(holder)
	if skin == "tooltip" then
		for i = 1, #parts do
			parts[i]:SetTexture(BORDER_TEX)
		end
		CropTooltip(holder)
		return
	end
	if skin == "solid" then
		for i = 1, #parts do
			parts[i]:SetTexture("Interface\\Buttons\\WHITE8X8")
			parts[i]:SetTexCoord(0, 1, 0, 1)
		end
		return
	end
	local art = DiveBar.MetalArt()
	for key, info in pairs(art) do
		local wrapH = (key == "top" or key == "bottom") and info.tilesHorizontally and "REPEAT" or "CLAMP"
		local wrapV = (key == "left" or key == "right") and info.tilesVertically and "REPEAT" or "CLAMP"
		holder[key]:SetTexture(info.file or info.filename, wrapH, wrapV)
	end
	local band = METAL_BAND
	local i = art.tl
	CropAtlas(holder.tl, i, METAL_L, METAL_L + band, METAL_T, METAL_T + band)
	i = art.tr
	CropAtlas(holder.tr, i, i.width - METAL_R - band, i.width - METAL_R, METAL_T, METAL_T + band)
	i = art.bl
	CropAtlas(holder.bl, i, METAL_L, METAL_L + band, i.height - METAL_B - band, i.height - METAL_B)
	i = art.br
	CropAtlas(holder.br, i, i.width - METAL_R - band, i.width - METAL_R, i.height - METAL_B - band, i.height - METAL_B)
	TileMetal(holder)
end

-- shade darkens the whole rim, for the XP badge.
local function PaintBorder(holder, theme, shade)
	shade = shade or 1
	local r, g, b = 1, 1, 1
	local skin = holder.skin
	if skin == "solid" then
		local color = theme.bandColor or theme.edgeTop or { 0.416, 0.416, 0.416 }
		r, g, b = color[1], color[2], color[3]
	elseif skin == "tooltip" and theme.edgeTint then
		r, g, b = theme.edgeTint[1], theme.edgeTint[2], theme.edgeTint[3]
	end
	local desaturate = skin == "metal" and theme.desaturate and true or false
	local parts = BorderParts(holder)
	for i = 1, #parts do
		parts[i]:SetDesaturated(desaturate)
		parts[i]:SetVertexColor(r * shade, g * shade, b * shade, 1)
	end
	local hairline = skin == "solid" and theme.hairline
	for i = 1, #holder.hairline do
		local line = holder.hairline[i]
		if hairline then
			line:SetVertexColor(hairline[1] * shade, hairline[2] * shade, hairline[3] * shade, 1)
		end
		line:SetShown(hairline and true or false)
	end
end

-- One physical screen pixel in the region's own units.
local function OnePixel(region)
	local scale = region:GetEffectiveScale() or 1
	local height = GetPhysicalScreenSize and select(2, GetPhysicalScreenSize())
	if not height or height <= 0 or scale <= 0 then
		return 1
	end
	return 768 / height / scale
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
		local tex = holder:CreateTexture(nil, "OVERLAY", nil, 6)
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
	-- The solid band's outer edge, drawn over it.
	holder.hairline = {}
	local edges = {
		{ "TOPLEFT", "TOPRIGHT" },
		{ "BOTTOMLEFT", "BOTTOMRIGHT" },
		{ "TOPLEFT", "BOTTOMLEFT" },
		{ "TOPRIGHT", "BOTTOMRIGHT" },
	}
	for i = 1, #edges do
		local line = holder:CreateTexture(nil, "OVERLAY", nil, 7)
		line:SetTexture("Interface\\Buttons\\WHITE8X8")
		line:SetPoint(edges[i][1], holder, edges[i][1], 0, 0)
		line:SetPoint(edges[i][2], holder, edges[i][2], 0, 0)
		line:Hide()
		holder.hairline[i] = line
	end
	CropTooltip(holder)
	holder.skin = "tooltip"
	holder.band = false
	holder:SetScript("OnSizeChanged", TileMetal)
	bar.border = holder
end

local function PlaceBorder(bar, thickness, rounded, fixed)
	local holder = bar.border
	local t = thickness
	if t < 1 then
		t = 1
	end
	-- The frame border yields when the frame is smaller than the line.
	-- The badge keeps the frame's line, so a short badge does not thin it.
	if not fixed then
		local w = bar:GetWidth() or 0
		local h = bar:GetHeight() or 0
		if w > 2 and t * 2 > w then
			t = w / 2
		end
		if h > 2 and t * 2 > h then
			t = h / 2
		end
	end
	holder:ClearAllPoints()
	holder:SetAllPoints(bar)
	local level = (bar:GetFrameLevel() or 0) + 20
	if holder:GetFrameLevel() ~= level then
		holder:SetFrameLevel(level)
	end
	-- A band is opaque, so it stops where the rows start. Its corners are its
	-- own (Forever's chamfers, or square), whatever Rounded corners says.
	local size = t
	if holder.band then
		size = DiveBar.ContentInset(t, true)
		rounded = true
	end
	holder.size = size
	local caps = { holder.tl, holder.tr, holder.bl, holder.br }
	for i = 1, #caps do
		caps[i]:SetShown(rounded and true or false)
	end
	if rounded then
		holder.tl:ClearAllPoints()
		holder.tl:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		holder.tl:SetSize(size, size)
		holder.tr:ClearAllPoints()
		holder.tr:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
		holder.tr:SetSize(size, size)
		holder.bl:ClearAllPoints()
		holder.bl:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
		holder.bl:SetSize(size, size)
		holder.br:ClearAllPoints()
		holder.br:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
		holder.br:SetSize(size, size)
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
	TileMetal(holder)
	local px = OnePixel(holder)
	holder.hairline[1]:SetHeight(px)
	holder.hairline[2]:SetHeight(px)
	holder.hairline[3]:SetWidth(px)
	holder.hairline[4]:SetWidth(px)
	holder:Show()
	return t
end

local CORNER_TEX = "Interface\\AddOns\\DiveBar\\DiveBarCorner"

local function Unsnap(texture)
	if texture.SetSnapToPixelGrid then
		texture:SetSnapToPixelGrid(false)
	end
	if texture.SetTexelSnappingBias then
		texture:SetTexelSnappingBias(0)
	end
end

-- The background follows the border's silver line. The pieces never overlap,
-- so a see-through background stays even.
local function MakeBackground(bar)
	local bg = {}
	local function piece(texture)
		local tex = bar:CreateTexture(nil, "BACKGROUND", nil, 0)
		tex:SetTexture(texture or "Interface\\Buttons\\WHITE8X8")
		Unsnap(tex)
		return tex
	end
	bg.mid = piece()
	bg.top = piece()
	bg.bottom = piece()
	bg.tl = piece(CORNER_TEX)
	bg.tr = piece(CORNER_TEX)
	bg.bl = piece(CORNER_TEX)
	bg.br = piece(CORNER_TEX)
	bg.tl:SetTexCoord(0, 1, 0, 1)
	bg.tr:SetTexCoord(1, 0, 0, 1)
	bg.bl:SetTexCoord(0, 1, 1, 0)
	bg.br:SetTexCoord(1, 0, 1, 0)
	bg.all = { bg.mid, bg.top, bg.bottom, bg.tl, bg.tr, bg.bl, bg.br }
	bar.bg = bg
end

local function PlaceBackground(bar, t, rounded, color, edge)
	local bg = bar.bg
	local r, g, b, a = color[1], color[2], color[3], color[4] or 1
	for i = 1, #bg.all do
		bg.all[i]:SetVertexColor(r, g, b, a)
	end
	edge = edge or t * DiveBar.BORDER_SILVER
	local mid = bg.mid
	mid:ClearAllPoints()
	if not rounded then
		mid:SetPoint("TOPLEFT", bar, "TOPLEFT", edge, -edge)
		mid:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -edge, edge)
		mid:Show()
		for i = 2, #bg.all do
			bg.all[i]:Hide()
		end
		return
	end
	local w = bar:GetWidth() or 0
	local h = bar:GetHeight() or 0
	local radius = t - edge
	mid:SetPoint("TOPLEFT", bar, "TOPLEFT", edge, -t)
	mid:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -edge, t)
	mid:SetShown(h > t * 2 + 0.01)
	bg.top:ClearAllPoints()
	bg.top:SetPoint("TOPLEFT", bar, "TOPLEFT", t, -edge)
	bg.top:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -t, -t)
	bg.bottom:ClearAllPoints()
	bg.bottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", t, edge)
	bg.bottom:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", -t, t)
	local strips = w > t * 2 + 0.01
	bg.top:SetShown(strips)
	bg.bottom:SetShown(strips)
	local corners = { { bg.tl, "TOPLEFT", 1, -1 }, { bg.tr, "TOPRIGHT", -1, -1 }, { bg.bl, "BOTTOMLEFT", 1, 1 }, { bg.br, "BOTTOMRIGHT", -1, 1 } }
	for i = 1, #corners do
		local tex, point, dx, dy = corners[i][1], corners[i][2], corners[i][3], corners[i][4]
		tex:ClearAllPoints()
		tex:SetPoint(point, bar, point, edge * dx, edge * dy)
		tex:SetSize(radius, radius)
		tex:Show()
	end
end

local BADGE_FILL = { 0.11, 0.11, 0.11, 0.95 }

-- The straight edges of the tooltip line are clear inside the silver. A single
-- inset deep enough for the rounded corner leaves the bars showing there.
-- The center stays inside the curve. Four strips close the clear band on the edges.
local function PlaceBadgeFill(badge, rim, rounded)
	local silver, corner = DiveBar.XPBadgeFillInset(rim, rounded)
	local fill = badge.fill
	fill:ClearAllPoints()
	local w = badge:GetWidth() or 0
	local h = badge:GetHeight() or 0
	local limit = 0
	if w > 0 and h > 0 then
		limit = math.min(w, h) * 0.5
	end
	if silver > limit then
		silver = limit
	end
	if corner > limit then
		corner = limit
	end
	local strips = rounded and corner > silver + 0.01 and w > corner * 2 and h > corner * 2
	if not strips then
		fill:SetPoint("TOPLEFT", badge, "TOPLEFT", silver, -silver)
		fill:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -silver, silver)
		if badge.edge then
			for i = 1, 4 do
				badge.edge[i]:Hide()
			end
		end
		return
	end
	fill:SetPoint("TOPLEFT", badge, "TOPLEFT", corner, -corner)
	fill:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -corner, corner)
	if not badge.edge then
		badge.edge = {}
		for i = 1, 4 do
			local tex = Solid(badge, "BACKGROUND", 0)
			Color(tex, BADGE_FILL)
			badge.edge[i] = tex
		end
	end
	local top, bottom, left, right = badge.edge[1], badge.edge[2], badge.edge[3], badge.edge[4]
	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", badge, "TOPLEFT", corner, -silver)
	top:SetPoint("BOTTOMRIGHT", badge, "TOPRIGHT", -corner, -corner)
	bottom:ClearAllPoints()
	bottom:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", corner, silver)
	bottom:SetPoint("TOPRIGHT", badge, "BOTTOMRIGHT", -corner, corner)
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", badge, "TOPLEFT", silver, -corner)
	left:SetPoint("BOTTOMRIGHT", badge, "BOTTOMLEFT", corner, corner)
	right:ClearAllPoints()
	right:SetPoint("TOPLEFT", badge, "TOPRIGHT", -corner, -corner)
	right:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -silver, corner)
	for i = 1, 4 do
		badge.edge[i]:Show()
	end
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
	Color(badge.fill, BADGE_FILL)
	-- The edge marker: a thin XP-blue line just inside the silver rim on the
	-- edge that marks the fill. It sits above the fill and under the rim and text.
	-- Its glow only ever bleeds to the left, toward the completed XP.
	badge.markGlow = Solid(badge, "ARTWORK", 1)
	badge.markGlow:Hide()
	badge.mark = Solid(badge, "ARTWORK", 2)
	badge.mark:Hide()
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
	MakeBackground(bar)
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
	bar.cast.time = bar.cast.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.cast.time:SetJustifyH("RIGHT")
	bar.cast.time:SetWordWrap(false)
	bar.cast.name:SetPoint("LEFT", bar.cast.overlay, "LEFT", 6, 0)
	bar.cast.time:SetPoint("RIGHT", bar.cast.overlay, "RIGHT", -6, 0)

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
	local rounded = theme.rounded ~= false
	local holder = bar.border
	SkinBorder(holder, theme.skin)
	local line = PlaceBorder(bar, thickness, rounded)
	local background = theme.background or { 0.02, 0.02, 0.02, 0.95 }
	if holder.band then
		-- Halfway into the band, the background's square corner stays inside the chamfer.
		PlaceBackground(bar, line, false, background, holder.size * 0.5)
	else
		PlaceBackground(bar, line, rounded, background)
	end
	PaintBorder(holder, theme)
end

function DiveBar:ApplyColors(bar, theme)
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
	return DiveBar.FitChrome(contentH, theme.borderSize, theme.rim, theme.rounded ~= false)
end

-- What the frame adds on each side of the Width setting: the border inset plus
-- any horizontal padding between the bars and that border.
function DiveBar:ChromeSide(profile, theme)
	local hpad = tonumber(profile and profile.hPadding) or 0
	if hpad < 0 then
		hpad = 0
	end
	return DiveBar.ContentInset(theme.rim, theme.rounded ~= false) + hpad
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

-- How far below the bar's top MarkAnchor's point sits, worked out from the layout
-- so it can be used before the frame has a position.
function DiveBar:AnchorDepth(blocks, tops, profile, inset, frameH)
	local mode, index = self.AnchorMeasure(blocks, self.OrderedFeatures(profile), self.NormalizeAnchor(profile))
	if mode == "center" then
		local feature = blocks[index].feature
		local first, last
		for i = 1, #blocks do
			if blocks[i].feature == feature then
				first = first or tops[i]
				last = tops[i] + blocks[i].h
			end
		end
		return inset + (first + last) / 2
	elseif mode == "top" then
		return inset + tops[index]
	elseif mode == "bottom" then
		return inset + tops[index] + blocks[index].h
	end
	return frameH / 2
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
	local hpad = tonumber(profile.hPadding) or 0
	if hpad < 0 then
		hpad = 0
	end
	local contentH = self.ContentHeight(blocks) + margin * 2
	if contentH < 1 then
		contentH = 1
	end
	local line, inset, frameH = self:ResolveChrome(contentH, theme)
	bar._fitRim = line
	-- The chrome hugs whatever is actually on screen. The background reaches
	-- the middle of the silver line and follows its curve in the corners.
	-- Horizontal padding insets the bars from the side border; the frame grows
	-- to keep the bars at the Width setting.
	bar:SetSize(width + inset * 2 + hpad * 2, frameH)
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
	local tops = {}
	for i = 1, #blocks do
		local block = blocks[i]
		tops[i] = top
		local row = self:BlockRow(bar, block)
		row:Show()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", bar.inner, "TOPLEFT", hpad, -top)
		row:SetPoint("TOPRIGHT", bar.inner, "TOPRIGHT", -hpad, -top)
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
	bar.anchorDepth = self:AnchorDepth(blocks, tops, profile, inset, frameH)
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
	else
		cast.name:Hide()
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
	local textSize = profile.xpBadgeTextSize or size
	if not text or style == "off" then
		badge:Hide()
		label:Hide()
		return
	end
	if style == "text" then
		badge:Hide()
		row.levelOverlay:SetFrameLevel(level)
		SetLevelText(label, text, textSize, "OUTLINE")
		local pad = 3
		local width = math.ceil(label:GetStringWidth() or 0) + pad * 2
		label:ClearAllPoints()
		label:SetPoint("LEFT", row.trough, "LEFT", self.XPBadgeOffset(filled, width, troughW) + pad, 0)
		label:Show()
		return
	end
	label:Hide()
	local rounded = theme.rounded ~= false
	local rim, padX, height = self.XPBadgeLayout(textSize, size, bar._fitRim or theme.rim, rounded)
	SetLevelText(badge.label, self.XPBadgeSample(profile.xpBadgeFormat), textSize, "")
	local contentW = badge.label:GetStringWidth() or 0
	SetLevelText(badge.label, text, textSize, "")
	local textW = badge.label:GetStringWidth() or 0
	if textW > contentW then
		contentW = textW
	end
	-- A touch of extra width (15%) past what the text and padding need, so the time reads in a roomier chip.
	local width = math.ceil((contentW + padX * 2) * 1.15)
	if width < 1 then
		width = 1
	end
	local badgeLevel = (bar:GetFrameLevel() or 0) + 21
	badge:SetFrameLevel(badgeLevel)
	badge:SetSize(width, height)
	badge:ClearAllPoints()
	local holder = badge.border
	SkinBorder(holder, theme.skin)
	-- The tooltip line starts after its soft shadow; a band starts at the edge.
	local shadow = holder.band and 0 or rim * self.BORDER_SHADOW
	local offset = self.XPBadgeOffset(filled, width, troughW, shadow)
	badge:SetPoint("LEFT", row.trough, "LEFT", offset, 0)
	PlaceBadgeFill(badge, rim, rounded)
	PlaceBorder(badge, rim, rounded, true)
	PaintBorder(holder, theme, holder.skin == "solid" and 1 or 0.85)
	-- Whichever rim edge lands on the end of the blue fill is the measuring edge.
	local rightMark = offset + width - shadow
	local leftMark = offset + shadow
	local markRight = math.abs(rightMark - filled) <= math.abs(leftMark - filled)
	local silver, corner = self.XPBadgeFillInset(rim, rounded)
	-- A band is opaque, so the marker moves in to its inner edge.
	if holder.band and holder.size > silver then
		silver = holder.size
	end
	-- Keep the marker clear of the rounded corners without inverting on a short badge.
	local halfH = height / 2
	if corner > halfH - 0.5 then
		corner = math.max(0, halfH - 0.5)
	end
	local markW = math.max(1, rim * 0.3)
	local mark = badge.mark
	Color(mark, self.XP_BADGE_MARK_COLOR)
	mark:SetWidth(markW)
	mark:ClearAllPoints()
	-- The glow bleeds left from the marker. On the right edge it stays inside
	-- the fill, short of the digits; on the left edge it runs out over the XP.
	local glow = badge.markGlow
	HGlow(glow, self.XP_BADGE_MARK_COLOR, 0.5)
	glow:ClearAllPoints()
	local reach = math.max(3, height * 0.6)
	if markRight then
		local clearance = (width - contentW) / 2 - silver
		if clearance < 1 then
			clearance = 1
		end
		if reach > clearance then
			reach = clearance
		end
		mark:SetPoint("TOPRIGHT", badge, "TOPRIGHT", -silver, -corner)
		mark:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -silver, corner)
		glow:SetPoint("TOPRIGHT", badge, "TOPRIGHT", -(silver + markW), -corner)
		glow:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -(silver + markW), corner)
	else
		mark:SetPoint("TOPLEFT", badge, "TOPLEFT", silver, -corner)
		mark:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", silver, corner)
		glow:SetPoint("TOPRIGHT", badge, "TOPLEFT", silver, -corner)
		glow:SetPoint("BOTTOMRIGHT", badge, "BOTTOMLEFT", silver, corner)
	end
	glow:SetWidth(reach)
	glow:Show()
	mark:Show()
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
	if opts.preview then
		-- The full layout sets where the anchor sits; folded layouts keep it there,
		-- as the bar keeps its anchor on screen.
		if opts.full or not self.previewAnchorDepth then
			self.previewAnchorDepth = bar.anchorDepth
			self.previewFullHeight = bar:GetHeight()
		end
		if self.previewHolder then
			bar:ClearAllPoints()
			bar:SetPoint("TOP", self.previewHolder, "TOP", 0, -6 - (self.previewAnchorDepth - bar.anchorDepth))
		end
		bar:SetShown((showing and not self.previewEmpty) and true or false)
	end
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

function DiveBar:PreviewWidth()
	local width = self.profile.width
	local limit = 620
	if self.previewHolder and self.previewHolder:GetWidth() and self.previewHolder:GetWidth() > 80 then
		limit = self.previewHolder:GetWidth() - 8
	end
	limit = limit - self:ChromeSide(self.profile, self:Theme()) * 2
	if width > limit then
		width = limit
	end
	return width
end

-- The demo moves the preview every frame. Its rows stay put, but the cast icon
-- comes and goes, and that needs a full layout.
function DiveBar:PaintPreview()
	if not self.preview or not self.profile or not self.options or not self.options:IsShown() then
		return
	end
	local sample = self:SampleState()
	local key = self:LayoutKey(sample)
	if key ~= self.previewLayoutKey then
		self.previewLayoutKey = key
		self:Present(self.preview, sample, { width = self:PreviewWidth(), preview = true })
		return
	end
	self:Paint(self.preview, sample, self:Theme(), self.profile, self:PreviewWidth())
end

function DiveBar:Refresh()
	if self.refreshing or not self.bar or not self.profile then
		return
	end
	self.refreshing = true
	self.OpenIntro(self.profile)
	if self.playerReady and self.Demoing(self.profile) and self.RequestTick then
		self:RequestTick()
	end
	self:Present(self.bar, self:BuildState(), { anchor = true })
	if self.preview then
		-- The preview area is sized with every ticked row up, so it holds still
		-- while the demo folds rows away inside it.
		local full = self:SampleState(true)
		self.previewEmpty = not (full.showCast or #full.swings > 0 or #full.timers > 0 or full.xp)
		self:Present(self.preview, full, { width = self:PreviewWidth(), preview = true, full = true })
		if self.FitPreview then
			self:FitPreview()
		end
		local sample = self:SampleState()
		self.previewLayoutKey = self:LayoutKey(sample)
		if self.previewLayoutKey ~= self:LayoutKey(full) then
			self:Present(self.preview, sample, { width = self:PreviewWidth(), preview = true })
		end
	end
	if self.SyncOptions and self.options and self.options:IsShown() then
		self:SyncOptions()
	end
	self.refreshing = false
end
