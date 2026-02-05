class_name HousingGrid
extends Control

# Configuración de la grilla
const TILE_SIZE := 64
const ROWS := 8
const COLS := 14

# Señales
signal tile_clicked(grid_pos: Vector2i, button_index: int)

# Estado
var is_editing := false : set = _set_is_editing

func _ready() -> void:
	# Aseguramos que el control tenga el tamaño correcto para contener la grilla
	custom_minimum_size = Vector2(COLS * TILE_SIZE, ROWS * TILE_SIZE)
	# Habilitar input del mouse
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if not is_editing:
		return
		
	if event is InputEventMouseButton and event.pressed:
		var local_pos := get_local_mouse_position()
		var grid_pos := local_to_grid(local_pos)
		
		if is_valid_cell(grid_pos):
			tile_clicked.emit(grid_pos, event.button_index)
			# Debug: print click
			print("Grid click: ", grid_pos)

func _set_is_editing(value: bool) -> void:
	is_editing = value
	# queue_redraw() # Ya no dibujamos lineas

# Utilidades
func local_to_grid(local_pos: Vector2) -> Vector2i:
	return Vector2i(local_pos / TILE_SIZE)

func grid_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * TILE_SIZE)

func is_valid_cell(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS
