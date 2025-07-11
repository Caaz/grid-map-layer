@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type(
		"GridMapLayer", 
		"TileMapLayer", 
		preload("./scripts/grid_map_layer.gd"), 
		preload("res://addons/grid_map_layer/assets/grid_map_layer_icon.svg")
	)
	add_custom_type(
		"GridMapLayerBaker", 
		"GridMap", 
		preload("./scripts/grid_map_layer_baker.gd"), 
		preload("res://addons/grid_map_layer/assets/grid_map_layer_baker_icon.svg")
	)


func _exit_tree():
	remove_custom_type("GridMapLayer")
	remove_custom_type("GridMapLayerBaker")
