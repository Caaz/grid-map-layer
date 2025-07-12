@tool
extends GridMap
class_name GridMapLayerBaker

@export var tile_set:TileSet:
	set(new_tileset):
		tile_set = new_tileset
		_update_internal_nodes()
		
@export var tile_set_source_id:int = 0:
	set(new_source):
		tile_set_source_id = new_source
		_update_internal_nodes()

@export var tile_subdivision:int = 0:
	set(new_subdivision):
		tile_subdivision = new_subdivision
		_update_internal_nodes()

@export var data_layer_name:String = "gml"

@export_tool_button("Update Display") var _update_display = _update_internal_nodes
@export_tool_button("Load Data from TileSet") var _load_data = load_data
@export_tool_button("Save Data to TileSet") var _bake_data = bake_data

var sub_viewport:SubViewport:
	get:
		if not is_instance_valid(sub_viewport):
			_create_internal_nodes()
		return sub_viewport

var tile_map_layer:TileMapLayer:
	get:
		if not is_instance_valid(tile_map_layer):
			_create_internal_nodes()
		return tile_map_layer

var sprite_3d:Sprite3D:
	get:
		if not is_instance_valid(sprite_3d):
			_create_internal_nodes()
		return sprite_3d

var tileset_source:TileSetAtlasSource:
	get:
		return tile_set.get_source(tile_set_source_id) as TileSetAtlasSource


## Creates internal nodes required for viewing the tile map below the gridmap interface
func _create_internal_nodes() -> void:
	if not _is_valid():
		return
	sub_viewport = SubViewport.new()
	tile_map_layer = TileMapLayer.new()
	sprite_3d = Sprite3D.new()
	sub_viewport.add_child(tile_map_layer, false, Node.INTERNAL_MODE_FRONT)
	add_child(sub_viewport, false, Node.INTERNAL_MODE_FRONT)
	add_child(sprite_3d, false, Node.INTERNAL_MODE_FRONT)
	_update_internal_nodes()
	
## Updates all internal nodes to ensure visuals match the settings.
func _update_internal_nodes() -> void:
	if not _is_valid():
		sprite_3d.hide()
		return
	sprite_3d.show()
	_update_tile_map_layer()
	_update_sub_viewport()
	_update_sprite_3d()

## Updates the tile_map with the current tileset.
func _update_tile_map_layer() -> void:
	tile_map_layer.tile_set = tile_set
	var grid_size:Vector2i = tileset_source.get_atlas_grid_size()
	tile_map_layer.clear()
	for y:int in range(grid_size.y):
		for x:int in range(grid_size.x):
			var coords:Vector2i = Vector2i(x,y)
			if not tileset_source.has_tile(coords):
				continue
				
			var tile = tileset_source.get_tile_at_coords(coords)
			tile_map_layer.set_cell(coords, tile_set_source_id, coords)

## Updates the sub viewport to have the correct sizze to contain the entire tileset
func _update_sub_viewport() -> void:
	var viewport_size:Vector2i = tile_map_layer.get_used_rect().end * tile_set.tile_size
	sub_viewport.size = viewport_size
	sub_viewport.transparent_bg = true

## Updates the sprite3D to be positioned correctly with the right pixel size for the current settings
func _update_sprite_3d() -> void:
	sprite_3d.texture = sub_viewport.get_texture()
	sprite_3d.pixel_size = cell_size.x / tile_set.tile_size.x * (tile_subdivision+1)
	sprite_3d.position.z = sprite_3d.pixel_size * sub_viewport.size.y
	sprite_3d.centered = false
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite_3d.rotation = Vector3(deg_to_rad(-90),0,0)

func _is_valid() -> bool:
	if not tileset_source:
		printerr("Gridmap TileSet Editor tileset_source invalid.")
		return false
		
	if not is_instance_valid(tile_set):
		printerr("TileSet not set")
		return false
		
	return true

func bake_data() -> void:
	if not tile_set.has_custom_data_layer_by_name(data_layer_name):
		tile_set.add_custom_data_layer()
		var index:int = tile_set.get_custom_data_layers_count()
		tile_set.set_custom_data_layer_name(index-1, data_layer_name)
		tile_set.set_custom_data_layer_type(index-1,Variant.Type.TYPE_ARRAY)
		
	var grid_size:Vector2i = tileset_source.get_atlas_grid_size()
	for y:int in range(grid_size.y):
		for x:int in range(grid_size.x):
			if not tileset_source.has_tile(Vector2i(x,y)):
				continue
				
			var gridmap_position:Vector3i = Vector3i(x*(tile_subdivision+1), 0, y*(tile_subdivision+1))
			var data:TileData = tileset_source.get_tile_data(Vector2i(x,y), 0)
			
			var tilemap_data:Array[Dictionary]
			for gy:int in range(gridmap_position.z, gridmap_position.z+(tile_subdivision+1)):
				for gx:int in range(gridmap_position.x, gridmap_position.x+(tile_subdivision+1)):
					var tile_position:Vector3i = Vector3i(gx,0,gy)
					var id = get_cell_item(tile_position)
					tilemap_data.append({
						"orientation":get_cell_item_orientation(tile_position),
						"id":id,
						"name":mesh_library.get_item_name(id),
					})
			data.set_custom_data(data_layer_name, tilemap_data)

func load_data() -> void:
	var grid_size:Vector2i = tileset_source.get_atlas_grid_size()
	for y:int in range(grid_size.y):
		for x:int in range(grid_size.x):
			if not tileset_source.has_tile(Vector2i(x,y)):
				continue
			var gridmap_position:Vector3i = Vector3i(x*(tile_subdivision+1), 0, y*(tile_subdivision+1))
			var data:TileData = tileset_source.get_tile_data(Vector2i(x,y), 0)
			var tiles:Array[Dictionary] = data.get_custom_data(data_layer_name)
			for tile_index:int in range(tiles.size()):
				var tile:Dictionary = tiles[tile_index]
				var subgrid_position:Vector3i = gridmap_position + Vector3i(tile_index % (tile_subdivision+1), 0, tile_index / (tile_subdivision+1))
				set_cell_item(subgrid_position, tile.get("id"), tile.get("orientation"))
