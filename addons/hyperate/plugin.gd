@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Add the "HypeRate" custom node to the editor
	add_custom_type("HypeRateSettings", "Resource", preload("hyperate_settings.gd"), preload("logo.png"))

	# Let Godot only instantiate one instance of the socket
	add_autoload_singleton("HypeRate", "res://addons/hyperate/hyperate.gd")

func _exit_tree() -> void:
	# Removes the "HypeRate" custom node
	remove_custom_type("HypeRateSettings")

	# Remove the singleton instance of the socket
	remove_autoload_singleton("HypeRate")
