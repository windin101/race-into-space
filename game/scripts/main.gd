extends Control
## Entry scene: hands over to the screen manager with the title screen.

const TITLE := "res://scenes/ui/title_screen.tscn"


func _ready() -> void:
	get_tree().root.theme = UiTheme.get_theme("usa")
	Screens.push(load(TITLE))
