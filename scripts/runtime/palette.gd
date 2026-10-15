## NEONLINE — Design tokens.
## Single source of truth for the visual language (colors, spacing, type scale,
## radii, elevation, motion). Every UI script pulls from here so the app stays
## consistent across screens and themes.
class_name NLPalette
extends Resource

enum ThemeId { MIDNIGHT, DAYLIGHT }

const THEMES: Dictionary = {
	ThemeId.MIDNIGHT: {
		"name": "Midnight Grid",
		"bg": Color("060d1a"),
		"bg_elevated": Color("0b1526"),
		"surface": Color("111f33"),
		"surface_alt": Color("18293f"),
		"surface_hairline": Color("24374f"),
		"text_primary": Color("eaf2ff"),
		"text_secondary": Color("93a6c4"),
		"text_disabled": Color("5b6c88"),
		"accent": Color("00e5ff"),
		"accent_pressed": Color("6bf3ff"),
		"accent_dim": Color("0a3f4a"),
		"secondary": Color("ff2e88"),
		"secondary_dim": Color("4a1030"),
		"tertiary": Color("b6ff3c"),
		"success": Color("2ee6a8"),
		"warning": Color("ffb020"),
		"error": Color("ff5252"),
		"on_accent": Color("001318"),
		"on_secondary": Color("ffffff"),
		"scrim": Color(0, 0, 0, 0.62),
		"ripple": Color(1, 1, 1, 0.10),
	},
	ThemeId.DAYLIGHT: {
		"name": "Daylight Protocol",
		"bg": Color("eef2f8"),
		"bg_elevated": Color("ffffff"),
		"surface": Color("ffffff"),
		"surface_alt": Color("e4eaf3"),
		"surface_hairline": Color("cdd7e4"),
		"text_primary": Color("0b1524"),
		"text_secondary": Color("4c5b70"),
		"text_disabled": Color("9aa7b8"),
		"accent": Color("0079a8"),
		"accent_pressed": Color("0a94c9"),
		"accent_dim": Color("cdeef7"),
		"secondary": Color("c2185b"),
		"secondary_dim": Color("f7d6e4"),
		"tertiary": Color("4f7a00"),
		"success": Color("0f8a5f"),
		"warning": Color("a86400"),
		"error": Color("c62828"),
		"on_accent": Color("ffffff"),
		"on_secondary": Color("ffffff"),
		"scrim": Color(11, 21, 36, 0.45),
		"ripple": Color(11, 21, 36, 0.10),
	},
}

# --- Spacing scale (4pt grid, mobile-safe) ---
const SPACE_XS := 4.0
const SPACE_S := 8.0
const SPACE_M := 12.0
const SPACE_L := 16.0
const SPACE_XL := 24.0
const SPACE_XXL := 32.0

# --- Corner radii ---
const RADIUS_S := 8.0
const RADIUS_M := 14.0
const RADIUS_L := 22.0
const RADIUS_PILL := 999.0

# --- Touch ergonomics (min 44dp targets, thumb zone aware) ---
const TOUCH_MIN := 44.0
const BUTTON_H_SM := 40.0
const BUTTON_H_MD := 48.0
const BUTTON_H_LG := 56.0
const NAV_BAR_H := 72.0
const TOP_BAR_H := 56.0
const LIST_ROW_H := 60.0
const GRID_GUTTER := 12.0

# --- Type scale (px @ default font size 16) ---
const FONT_SCALE := {
	"display": 30.0,
	"title": 22.0,
	"headline": 18.0,
	"body": 15.0,
	"label": 14.0,
	"caption": 12.0,
	"overline": 11.0,
}

# --- Motion (seconds) ---
const MOTION_FAST := 0.12
const MOTION_BASE := 0.20
const MOTION_SLOW := 0.32


static func theme_ids() -> Array:
	return THEMES.keys()


static func colors(id: int) -> Dictionary:
	return THEMES.get(id, THEMES[ThemeId.MIDNIGHT])
