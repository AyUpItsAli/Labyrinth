extends Node2D

# Constants & Enums
enum TileTypes { STRAIGHT, CORNER, JUNCTION, IMMOVEABLE, HOME, DISABLED_HOME  }
const TILE_ROTATIONS = [0,90,180,270]
const MOVEABLE_TILES = [
	0,0,0,0,0,0,0,0,0,0,0,0,
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	2,2,2,2,2,2
]

# Fields
onready var num_players = 2 # TODO: Set to Network.players.size()
var tiles = [] # List containing other lists (rows) of tile ids for tiles on the grid
var action_tile: int # Tile id for action tile (tile left over after grid init)

func initialize(tiles_in = null):
	if tiles_in: tiles = tiles_in
	else: create_tiles()
	initialize_tiles()
	
func create_tiles():
	var moveable_tiles = MOVEABLE_TILES.duplicate()
	for row in range(7):
		var row_tiles = []
		for column in range(7):
			var tile_type = null
			# Home tiles
			if (row == 0 or row == 6) and (column == 0 or column == 6):
				match num_players:
					1, 2:
						if (row == 0 and column == 0) or (row == 6 and column == 6): tile_type = TileTypes.HOME
						else: tile_type = TileTypes.DISABLED_HOME
					3:
						if (row == 6 and column == 6): tile_type = TileTypes.DISABLED_HOME
						else: tile_type = TileTypes.HOME
						
					4: tile_type = TileTypes.HOME
			# Immoveable tiles
			if (row == 0 or row == 6) and (column == 2 or column == 4): tile_type = TileTypes.IMMOVEABLE
			if (row == 2 or row == 4) and (column == 0 or column == 2 or column == 4 or column == 6): tile_type = TileTypes.IMMOVEABLE
			
			# Other tiles
			if moveable_tiles.size() > 0 and tile_type == null:
				tile_type = Utils.choose(moveable_tiles)
				moveable_tiles.erase(tile_type)
			
			var tile_rotation = 0
			match tile_type:
				TileTypes.STRAIGHT, TileTypes.CORNER, TileTypes.JUNCTION:
					tile_rotation = Utils.choose(TILE_ROTATIONS)
				TileTypes.IMMOVEABLE:
					if column == 0: tile_rotation = 180
					elif row == 0: tile_rotation = 270
					elif row == 6: tile_rotation = 90
					else: match Vector2(column,row):
						Vector2(2,2): tile_rotation = 180
						Vector2(4,2): tile_rotation = 270
						Vector2(2,4): tile_rotation = 90
				TileTypes.HOME, TileTypes.DISABLED_HOME:
					match Vector2(column,row):
						Vector2(0,0): tile_rotation = 180
						Vector2(0,6): tile_rotation = 90
						Vector2(6,0): tile_rotation = 270
				
			row_tiles.append([tile_type, tile_rotation])
		tiles.append(row_tiles)
	action_tile = moveable_tiles.pop_front()

func initialize_tiles():
	for row in range(tiles.size()):
		for column in range(tiles[row].size()):
			var pos = Vector2(column, row)
			var tile_type = tiles[row][column][0]
			var tile_rotation = tiles[row][column][1]
			var tile_item: int
			for item_category in ItemManager.tile_items:
				for item in item_category:
					var item_index = item[0]
					var item_pos: Vector2 = item[1]
					if pos.x == item_pos.x and pos.y == item_pos.y: tile_item = item_index
			
			get_child(row).get_child(column).initialize(pos, tile_type, tile_rotation, tile_item)