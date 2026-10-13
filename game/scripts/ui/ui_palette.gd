class_name UiPalette
extends RefCounted
## Colour tokens for the whole UI. Every colour in a screen comes from here, never from
## a literal, so the two side themes (US blue, Soviet red) and later skins stay coherent.

const BG := Color("0b1526")
const BG_DEEP := Color("070e1b")
const PANEL := Color("15223a")
const PANEL_RAISED := Color("1e2f4d")
const PANEL_SUNKEN := Color("0f1a2e")
const BORDER := Color("3b4f73")
const BORDER_SOFT := Color("263756")
const TEXT := Color("e9e4d6")
const TEXT_DIM := Color("9aa5b8")
const TEXT_MUTED := Color("66728a")
const OK := Color("4caf50")
const WARN := Color("e0b84c")
const DANGER := Color("d9534f")
const INFO := Color("5aa9e6")
const GOLD := Color("d4a84b")
## Monotone backdrop hues per side (ui-style-guide section 3).
const ROOM_TINT_USA := Color("2a4d8c")
const ROOM_TINT_USSR := Color("8c2a2a")

const ACCENT_USA := Color("3d7bdc")
const ACCENT_USA_DARK := Color("27509a")
const ACCENT_USSR := Color("d23a2f")
const ACCENT_USSR_DARK := Color("8e241c")


## Side colours come from the registry (data/sides.json); the constants above are the
## first two sides' values, kept for code that needs a compile-time colour.
static func accent(side: String) -> Color:
	return Sides.colour(side, "accent") if Sides.exists(side) else ACCENT_USA


static func accent_dark(side: String) -> Color:
	return Sides.colour(side, "accent_dark") if Sides.exists(side) else ACCENT_USA_DARK


static func room_tint(side: String) -> Color:
	return Sides.colour(side, "room_tint") if Sides.exists(side) else ROOM_TINT_USA


## Colour for a safety percentage, matching the readiness bands.
static func safety_color(pct: int) -> Color:
	if pct >= 75:
		return OK
	if pct >= 50:
		return WARN
	return DANGER


static func mood_color(mood: int) -> Color:
	if mood >= 70:
		return OK
	if mood >= 40:
		return WARN
	return DANGER
