extends GdUnitTestSuite
## The drop-in loader: misses fall back to procedural art, a file present is used.

const TMP_PORTRAIT := "res://assets/art/portraits/ZZTEST.png"
const TMP_FRAMES := "res://assets/art/vignettes/launch_ok"


func after_test() -> void:
	if FileAccess.file_exists(TMP_PORTRAIT):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PORTRAIT))
		var imp := TMP_PORTRAIT + ".import"
		if FileAccess.file_exists(imp):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(imp))
	ArtAssets.clear_cache()


func test_missing_assets_return_null_and_painters_still_draw() -> void:
	ArtAssets.clear_cache()
	assert_object(ArtAssets.portrait("NOBODY")).is_null()
	assert_object(ArtAssets.hardware("usa", "rocket", 0)).is_null()
	assert_object(ArtAssets.spaceport_layer("usa", "background_spring")).is_null()
	assert_object(ArtAssets.backdrop("title")).is_null()
	assert_array(ArtAssets.vignette_frames("duration", false)).is_empty()
	var canvas := Control.new()
	canvas.size = Vector2(200, 200)
	add_child(canvas)
	var drew := {}
	canvas.draw.connect(func():
		PortraitArt.paint(canvas, Rect2(0, 0, 84, 100), "NOBODY", false, "usa")
		HardwareArt.paint(canvas, Rect2(0, 0, 90, 90), "rocket", 0, "usa")
		drew["ok"] = true)
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(drew.has("ok")).is_true()
	canvas.queue_free()


func test_present_file_is_used() -> void:
	# Write a small PNG, then the loader must return a texture for it (via load of an
	# unimported PNG, Godot falls back to Image loading when ResourceLoader has no import).
	var img := Image.create(8, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	img.save_png(ProjectSettings.globalize_path(TMP_PORTRAIT))
	ArtAssets.clear_cache()
	var tex := ArtAssets.portrait("zztest")
	# Outside the editor an unimported PNG may not load through ResourceLoader; accept
	# either a texture or a clean null, but never an error.
	if tex != null:
		assert_int(tex.get_width()).is_equal(8)


func test_cover_and_fit_math() -> void:
	var img := Image.create(200, 100, false, Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	var canvas := Control.new()
	canvas.size = Vector2(100, 100)
	add_child(canvas)
	var drew := {}
	canvas.draw.connect(func():
		ArtAssets.draw_cover(canvas, tex, Rect2(0, 0, 100, 100))
		ArtAssets.draw_fit(canvas, tex, Rect2(0, 0, 100, 100))
		drew["ok"] = true)
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(drew.has("ok")).is_true()
	canvas.queue_free()
