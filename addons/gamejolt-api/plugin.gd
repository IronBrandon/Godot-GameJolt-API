@tool extends EditorPlugin

const GAMEJOLT_SCRIPT: GDScript = preload("gamejolt.gd")
const GAMEJOLT_ICON: Texture2D = preload("gamejolt_icon.png")

func _enter_tree() -> void: # When this plugin node enters the tree
	add_custom_type("GameJoltAPI", "HTTPRequest", GAMEJOLT_SCRIPT, GAMEJOLT_ICON)

func _exit_tree() -> void: # When this plugin node exits the tree
	remove_custom_type("GameJoltAPI")
