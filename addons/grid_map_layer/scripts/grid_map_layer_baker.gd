@tool
extends GridMap
class_name GridMapLayerBaker

@onready var sprite:Sprite3D:
	get:
		if get_child_count(true) > 0:
			var child := get_child(0, true)
			if child is Sprite3D:
				return child
		
		var new_sprite:Sprite3D = Sprite3D.new()
		add_child(new_sprite, false, Node.INTERNAL_MODE_FRONT)
		return new_sprite

@export var tile_set:TileSet:
	set(new_tileset):
		tile_set = new_tileset
		_tileset_updated()
		
@export var tile_set_source_id:int = 0:
	set(new_source):
		tile_set_source_id = new_source
		_tileset_updated()

@export var tile_subdivision:int = 0:
	set(new_subdivision):
		tile_subdivision = new_subdivision
		_tileset_updated()

@export var data_layer_name:String = "gml"
var tileset_source:TileSetAtlasSource:
	get:
		return tile_set.get_source(tile_set_source_id) as TileSetAtlasSource

@export_tool_button("Load Data from TileSet") var test_func = func():
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

@export_tool_button("Save Data to TileSet") var bake_data = func():
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

func _tileset_updated():
	if not tileset_source:
		printerr("Gridmap Tileset Editor tileset_source invalid.")
		sprite.hide()
		return
	
	sprite.texture = tileset_source.texture
	var tile_size:Vector2i = tile_set.tile_size
	if tile_size.x != tile_size.y:
		printerr("Gridmap Tileset Editor only supports square tile sizes.")
		sprite.hide()
		return

	if cell_size.x != cell_size.z:
		printerr("Gridmap Tileset Editor only supports square cell sizes. (x != z)")
		sprite.hide()
		return
	
	sprite.show()
	sprite.pixel_size = cell_size.x / tile_size.x * (tile_subdivision+1)
	sprite.position.z = sprite.pixel_size * tileset_source.texture.get_height()
	sprite.centered = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.rotation = Vector3(deg_to_rad(-90),0,0)

	
