class_name UiTheme
extends RefCounted
## Builds the game's Theme in code from UiPalette tokens and the bundled MSDF fonts.
## One theme per side; the accent colour is the only difference.
##
## Type variations available to scenes:
##   Label:  "Title", "Heading", "Subheading", "Dim", "Mono"
##   Button: "Accent", "Danger", "Flat"
##   PanelContainer: "Raised", "Sunken", "Card"

const FONT_BODY := "res://assets/fonts/SourceSans3-Regular.otf"
const FONT_BODY_SEMIBOLD := "res://assets/fonts/SourceSans3-Semibold.otf"
const FONT_BODY_BOLD := "res://assets/fonts/SourceSans3-Bold.otf"
const FONT_HEADING := "res://assets/fonts/Oswald-Variable.ttf"

## Sizes in logical pixels at the 1920x1080 design resolution.
const SIZE_BODY := 18
const SIZE_SMALL := 15
const SIZE_SUBHEADING := 22
const SIZE_HEADING := 30
const SIZE_TITLE := 56
const RADIUS := 6
const BORDER_W := 1
const PAD := 10

static var _cache: Dictionary = {}


static func get_theme(side: String) -> Theme:
	if not _cache.has(side):
		_cache[side] = build(side)
	return _cache[side]


static func font(path: String) -> Font:
	var f := load(path)
	if f == null:
		push_warning("UiTheme: font missing %s, falling back to default" % path)
		return ThemeDB.fallback_font
	return f


static func flat(bg: Color, border: Color = Color.TRANSPARENT, radius: int = RADIUS, border_w: int = BORDER_W) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w if border.a > 0 else 0)
	sb.border_color = border
	sb.set_content_margin_all(PAD)
	return sb


static func build(side: String) -> Theme:
	var t := Theme.new()
	var accent := UiPalette.accent(side)
	var accent_dark := UiPalette.accent_dark(side)
	var body := font(FONT_BODY)
	var semibold := font(FONT_BODY_SEMIBOLD)
	var bold := font(FONT_BODY_BOLD)
	var heading := font(FONT_HEADING)

	t.default_font = body
	t.default_font_size = SIZE_BODY

	# Labels
	t.set_color("font_color", "Label", UiPalette.TEXT)
	for variation in ["Title", "Heading", "Subheading", "Dim", "Mono", "Small"]:
		t.add_type(variation)
		t.set_type_variation(variation, "Label")
	t.set_font("font", "Title", heading)
	t.set_font_size("font_size", "Title", SIZE_TITLE)
	t.set_color("font_color", "Title", UiPalette.TEXT)
	t.set_font("font", "Heading", heading)
	t.set_font_size("font_size", "Heading", SIZE_HEADING)
	t.set_color("font_color", "Heading", accent.lightened(0.35))
	t.set_font("font", "Subheading", semibold)
	t.set_font_size("font_size", "Subheading", SIZE_SUBHEADING)
	t.set_color("font_color", "Dim", UiPalette.TEXT_DIM)
	t.set_font_size("font_size", "Small", SIZE_SMALL)
	t.set_color("font_color", "Small", UiPalette.TEXT_DIM)
	t.set_font("font", "Mono", semibold)

	# Buttons
	t.set_font("font", "Button", semibold)
	t.set_font_size("font_size", "Button", SIZE_BODY)
	t.set_color("font_color", "Button", UiPalette.TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", UiPalette.TEXT_MUTED)
	t.set_stylebox("normal", "Button", flat(UiPalette.PANEL_RAISED, UiPalette.BORDER))
	t.set_stylebox("hover", "Button", flat(UiPalette.PANEL_RAISED.lightened(0.08), accent))
	t.set_stylebox("pressed", "Button", flat(accent_dark, accent))
	t.set_stylebox("disabled", "Button", flat(UiPalette.PANEL, UiPalette.BORDER_SOFT))
	var focus := flat(Color.TRANSPARENT, accent, RADIUS, 2)
	t.set_stylebox("focus", "Button", focus)
	for variation in ["Accent", "Danger", "Flat"]:
		t.add_type(variation)
		t.set_type_variation(variation, "Button")
	t.set_stylebox("normal", "Accent", flat(accent, accent.lightened(0.2)))
	t.set_stylebox("hover", "Accent", flat(accent.lightened(0.12), Color.WHITE))
	t.set_stylebox("pressed", "Accent", flat(accent_dark, Color.WHITE))
	t.set_stylebox("normal", "Danger", flat(UiPalette.DANGER.darkened(0.3), UiPalette.DANGER))
	t.set_stylebox("hover", "Danger", flat(UiPalette.DANGER, Color.WHITE))
	t.set_stylebox("pressed", "Danger", flat(UiPalette.DANGER.darkened(0.5), Color.WHITE))
	t.set_stylebox("normal", "Flat", flat(Color.TRANSPARENT))
	t.set_stylebox("hover", "Flat", flat(UiPalette.PANEL_RAISED))
	t.set_stylebox("pressed", "Flat", flat(accent_dark))

	# Panels
	t.set_stylebox("panel", "PanelContainer", flat(UiPalette.PANEL, UiPalette.BORDER_SOFT))
	t.set_stylebox("panel", "Panel", flat(UiPalette.PANEL, UiPalette.BORDER_SOFT))
	for variation in ["Raised", "Sunken", "Card"]:
		t.add_type(variation)
		t.set_type_variation(variation, "PanelContainer")
	t.set_stylebox("panel", "Raised", flat(UiPalette.PANEL_RAISED, UiPalette.BORDER))
	t.set_stylebox("panel", "Sunken", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT))
	t.set_stylebox("panel", "Card", flat(UiPalette.PANEL_RAISED, accent_dark, RADIUS, 2))

	# Inputs and lists
	t.set_stylebox("normal", "LineEdit", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER))
	t.set_stylebox("focus", "LineEdit", flat(UiPalette.PANEL_SUNKEN, accent, RADIUS, 2))
	t.set_color("font_color", "LineEdit", UiPalette.TEXT)
	t.set_stylebox("panel", "Tree", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT))
	t.set_stylebox("panel", "ItemList", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT))
	t.set_stylebox("panel", "ScrollContainer", flat(Color.TRANSPARENT))
	t.set_color("font_color", "Tree", UiPalette.TEXT)
	t.set_stylebox("normal", "OptionButton", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER))
	t.set_stylebox("hover", "OptionButton", flat(UiPalette.PANEL_SUNKEN, accent))
	t.set_stylebox("pressed", "OptionButton", flat(accent_dark, accent))
	t.set_color("font_color", "OptionButton", UiPalette.TEXT)
	t.set_stylebox("panel", "PopupMenu", flat(UiPalette.PANEL_RAISED, UiPalette.BORDER))
	t.set_color("font_color", "PopupMenu", UiPalette.TEXT)
	t.set_stylebox("hover", "PopupMenu", flat(accent_dark))
	t.set_stylebox("panel", "PopupPanel", flat(UiPalette.PANEL_RAISED, UiPalette.BORDER))
	t.set_stylebox("slider", "HSlider", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER, 4))
	t.set_stylebox("grabber_area", "HSlider", flat(accent, Color.TRANSPARENT, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(accent.lightened(0.2), Color.TRANSPARENT, 4))
	t.set_stylebox("panel", "CheckButton", flat(Color.TRANSPARENT))
	t.set_color("font_color", "CheckButton", UiPalette.TEXT)
	t.set_color("font_color", "CheckBox", UiPalette.TEXT)

	# Progress bars (stat bars)
	t.set_stylebox("background", "ProgressBar", flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT, 4, 1))
	t.set_stylebox("fill", "ProgressBar", flat(accent, Color.TRANSPARENT, 4))
	t.set_color("font_color", "ProgressBar", UiPalette.TEXT)
	t.set_font_size("font_size", "ProgressBar", SIZE_SMALL)

	# Tooltips and dialogs
	t.set_stylebox("panel", "TooltipPanel", flat(UiPalette.BG_DEEP, accent, RADIUS, 1))
	t.set_color("font_color", "TooltipLabel", UiPalette.TEXT)
	t.set_font_size("font_size", "TooltipLabel", SIZE_SMALL)
	t.set_stylebox("panel", "AcceptDialog", flat(UiPalette.PANEL_RAISED, accent, RADIUS, 2))
	t.set_font("title_font", "Window", heading)
	t.set_font_size("title_font_size", "Window", SIZE_SUBHEADING)
	t.set_color("title_color", "Window", UiPalette.TEXT)

	t.set_constant("separation", "HBoxContainer", 8)
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("h_separation", "GridContainer", 12)
	t.set_constant("v_separation", "GridContainer", 6)
	t.set_font("font", "RichTextLabel", body)
	t.set_font("bold_font", "RichTextLabel", bold)
	t.set_color("default_color", "RichTextLabel", UiPalette.TEXT)
	return t
