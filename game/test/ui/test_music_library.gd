extends GdUnitTestSuite
## Original-music support: a folder of the original game's tracks is matched by name
## (any case), missing tracks fall back to our soundtrack, and an empty folder changes
## nothing. Our own Ogg files stand in for the original ones here.

const TMP := "user://test_original_music"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP))
	MusicLibrary.clear_index()


func after_test() -> void:
	var dir := DirAccess.open(TMP)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	MusicLibrary.clear_index()


func _fake(name: String) -> void:
	var src := FileAccess.get_file_as_bytes("res://assets/audio/music/mission.ogg")
	var f := FileAccess.open(TMP.path_join(name), FileAccess.WRITE)
	f.store_buffer(src)
	f.close()


func _dir() -> String:
	return ProjectSettings.globalize_path(TMP)


func test_every_ours_track_in_the_map_exists() -> void:
	for group in ["screens", "events"]:
		for key in MusicLibrary.map()[group]:
			var ours := str(MusicLibrary.map()[group][key].get("ours", ""))
			if ours != "":
				assert_bool(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % ours)).override_failure_message("missing ours track " + ours).is_true()


func test_original_track_found_in_any_case() -> void:
	_fake("USPORT2.OGG")
	_fake("R&D.ogg")
	var r := MusicLibrary.resolve("spaceport_usa", "original", _dir())
	assert_str(r["source"]).is_equal("original")
	assert_str(str(r["path"]).get_file()).is_equal("USPORT2.OGG")
	assert_str(MusicLibrary.resolve("research", "original", _dir())["source"]).is_equal("original")
	assert_object(MusicLibrary.load_external(r["path"])).is_not_null()


func test_missing_original_falls_back_to_ours() -> void:
	_fake("theme.ogg")
	var r := MusicLibrary.resolve("vehicle_assembly", "original", _dir())
	assert_str(r["source"]).is_equal("ours")
	assert_str(r["stem"]).is_equal("spaceport_day")


func test_ours_selected_ignores_the_folder() -> void:
	_fake("theme.ogg")
	assert_str(MusicLibrary.resolve("title_screen", "ours", _dir())["source"]).is_equal("ours")


func test_folder_check_counts_tracks() -> void:
	_fake("theme.ogg")
	_fake("Assembly.OGG")
	var r := MusicLibrary.check_folder(_dir())
	assert_bool(r["found"].has("theme")).is_true()
	assert_bool(r["found"].has("assembly")).is_true()
	assert_bool(r["missing"].has("victory")).is_true()


func test_empty_folder_finds_nothing() -> void:
	assert_bool(MusicLibrary.check_folder(_dir())["found"].is_empty()).is_true()
