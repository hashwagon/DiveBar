-- Colors sampled from the Forever unit frame and the approved cast-bar mockup.

DiveBar = DiveBar or {}

local function theme(values)
	return values
end

DiveBar.THEMES = {
	Forever = theme({
		rim = 5,
		pad = 3,
		gap = 3,
		lip = 1,
		metal = { 0.490, 0.353, 0.196 },
		edgeTop = { 0.953, 0.886, 0.737 },
		edgeLeft = { 0.902, 0.816, 0.627 },
		edgeRight = { 0.227, 0.157, 0.086 },
		edgeBottom = { 0.102, 0.063, 0.031 },
		inner = { 0.055, 0.043, 0.031 },
		trough = { 0.427, 0.329, 0.220 },
		background = { 0.03, 0.024, 0.018, 0.95 },
		empty = { 0.095, 0.078, 0.06 },
		troughTop = { 0.651, 0.518, 0.345 },
		namePlate = true,
		nameBG = { 0.047, 0.043, 0.345 },
		text = { 1, 0.824, 0 },
		cast = { 0.141, 0.341, 0.722 },
		castTop = { 0.431, 0.604, 0.878 },
		channel = { 0.302, 0.478, 0.290 },
		channelTop = { 0.557, 0.682, 0.518 },
		interrupt = { 0.478, 0.235, 0.220 },
		interruptTop = { 0.659, 0.416, 0.392 },
		latency = { 0.027, 0.078, 0.157, 0.72 },
		melee = { 1, 0.74, 0.35 },
		meleeTop = { 1, 0.90, 0.62 },
		off = { 0.86, 0.55, 0.26 },
		offTop = { 1, 0.78, 0.48 },
		steel = { 0.427, 0.565, 0.667 },
		steelTop = { 0.835, 0.886, 0.925 },
		spark = { 1, 0.953, 0.769 },
		iconEdge = { 0.953, 0.886, 0.737 },
		iconEdgeShadow = { 0.227, 0.157, 0.086 },
		lipColor = { 0.416, 0.306, 0.173 },
		lipTop = { 0.941, 0.867, 0.706 },
		lipBottom = { 0.110, 0.071, 0.047 },
	}),
	Flat = theme({
		rim = 2,
		pad = 2,
		gap = 3,
		lip = 1,
		metal = { 0.165, 0.165, 0.165 },
		edgeTop = { 0.416, 0.416, 0.416 },
		edgeLeft = { 0.416, 0.416, 0.416 },
		edgeRight = { 0.416, 0.416, 0.416 },
		edgeBottom = { 0.416, 0.416, 0.416 },
		inner = { 0.063, 0.063, 0.063 },
		trough = { 0.102, 0.102, 0.102 },
		background = { 0.025, 0.025, 0.025, 0.95 },
		empty = { 0.085, 0.085, 0.085 },
		troughTop = { 0.102, 0.102, 0.102 },
		namePlate = false,
		nameBG = { 0, 0, 0, 0 },
		text = { 1, 0.824, 0 },
		cast = { 0.141, 0.341, 0.722 },
		castTop = { 0.431, 0.604, 0.878 },
		channel = { 0.302, 0.478, 0.290 },
		channelTop = { 0.557, 0.682, 0.518 },
		interrupt = { 0.478, 0.235, 0.220 },
		interruptTop = { 0.659, 0.416, 0.392 },
		latency = { 0.027, 0.078, 0.157, 0.72 },
		melee = { 1, 0.74, 0.35 },
		meleeTop = { 1, 0.90, 0.62 },
		off = { 0.86, 0.55, 0.26 },
		offTop = { 1, 0.78, 0.48 },
		steel = { 0.427, 0.565, 0.667 },
		steelTop = { 0.835, 0.886, 0.925 },
		spark = { 1, 0.953, 0.769 },
		flatBorder = true,
		iconEdge = { 0.361, 0.361, 0.361 },
		iconEdgeShadow = { 0.361, 0.361, 0.361 },
		lipColor = { 0.28, 0.28, 0.28 },
		lipTop = { 0.48, 0.48, 0.48 },
		lipBottom = { 0.16, 0.16, 0.16 },
	}),
	Classic = theme({
		rim = 5,
		pad = 3,
		gap = 3,
		lip = 1,
		metal = { 0.878, 0.690, 0.180 },
		edgeTop = { 1, 0.965, 0.769 },
		edgeLeft = { 1, 0.914, 0.541 },
		edgeRight = { 0.651, 0.518, 0.071 },
		edgeBottom = { 0.416, 0.329, 0.031 },
		inner = { 0.047, 0.047, 0.047 },
		trough = { 0.078, 0.078, 0.078 },
		background = { 0.025, 0.025, 0.025, 0.95 },
		empty = { 0.085, 0.085, 0.085 },
		troughTop = { 0.078, 0.078, 0.078 },
		namePlate = false,
		nameBG = { 0, 0, 0, 0 },
		text = { 1, 0.824, 0 },
		cast = { 0.122, 0.365, 0.831 },
		castTop = { 0.663, 0.784, 1 },
		channel = { 0.129, 0.478, 0.188 },
		channelTop = { 0.714, 0.910, 0.659 },
		interrupt = { 0.541, 0.141, 0.122 },
		interruptTop = { 0.886, 0.533, 0.502 },
		latency = { 0.05, 0.12, 0.28, 0.55 },
		melee = { 1, 0.74, 0.35 },
		meleeTop = { 1, 0.90, 0.62 },
		off = { 0.86, 0.55, 0.26 },
		offTop = { 1, 0.78, 0.48 },
		steel = { 0.427, 0.565, 0.667 },
		steelTop = { 0.835, 0.886, 0.925 },
		spark = { 1, 0.973, 0.82 },
		iconEdge = { 1, 0.953, 0.690 },
		iconEdgeShadow = { 0.541, 0.439, 0.031 },
		lipColor = { 0.902, 0.765, 0.290 },
		lipTop = { 1, 0.965, 0.769 },
		lipBottom = { 0.353, 0.267, 0.031 },
	}),
}

function DiveBar:Theme()
	local name = self.profile and self.profile.theme
	local base = self.THEMES[name] or self.THEMES.Forever
	if not self.profile then
		return base
	end
	local border = tonumber(self.profile.border) or 3
	if border < 1 then
		border = 1
	elseif border > 20 then
		border = 20
	end
	local theme = {}
	for key, value in pairs(base) do
		theme[key] = value
	end
	-- Tooltip border art. The slider scales the gold line. The background
	-- tucks under that line; FitChrome sets the smaller inset.
	local edgeSize = math.floor(10 + (border - 1) * (26 / 19) + 0.5)
	local rim = DiveBar.BorderThickness(edgeSize)
	theme.rim = rim
	theme.edge = rim
	theme.pad = 0
	theme.gap = 0
	theme.lip = 0
	theme.borderSize = edgeSize
	return theme
end
