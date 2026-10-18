extends Control
## Entry scene: hands over to the screen manager with the title screen.
## `--self-check` (after `--` on the command line) instead verifies that the packed data
## and art load, prints one line per check and exits non-zero on any failure: a smoke test
## for exported builds, which cannot run outside scripts.

const TITLE := "res://scenes/ui/title_screen.tscn"


func _ready() -> void:
	if "--self-check" in OS.get_cmdline_user_args():
		get_tree().quit(_self_check())
		return
	get_tree().root.theme = UiTheme.get_theme("usa")
	Screens.push(load(TITLE))


func _self_check() -> int:
	var failures := 0
	var checks := [
		["data tables", GameData.missions.size() > 0 and Sides.ids().size() >= 3],
		["hardware art", ArtAssets.hardware("usa", "manned", 2) != null and ArtAssets.hardware("cwth", "rocket", 0) != null],
		["spaceport art", ArtAssets.texture("spaceport/ussr/background_spring.png") != null],
		["vehicle vignette", ArtAssets.vignette_frames("reentry", true, "ussr", "manned_0").size() == 36],
		["generic vignette", ArtAssets.vignette_frames("photo", true).size() > 0],
		["portraits", ArtAssets.portrait("SVETLANA IZVESTIA") != null],
		["text casing", TextCase.sentence("THE KGB AND NASA.") == "The KGB and NASA."],
		["music", ResourceLoader.exists("res://assets/audio/music/title_theme.ogg")],
	]
	for c in checks:
		print("SELF-CHECK %s: %s" % [c[0], "ok" if c[1] else "FAILED"])
		if not c[1]:
			failures += 1
	print("SELF-CHECK %s" % ("PASSED" if failures == 0 else "FAILED (%d)" % failures))
	return 0 if failures == 0 else 1
