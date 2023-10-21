extends CanvasLayer

@onready var scroll_container = %ScrollContainer
@onready var items_v_box_container = %ItemsVBoxContainer
@onready var task_item_resource: PackedScene = preload("res://addons/first_person_controller/examples/debug/scenes/task_item.tscn")

var prev_mouse_mode: Input.MouseMode
var is_dirty: bool

func _process(_delta):
	if is_dirty:
		is_dirty = false
		_refresh_contents()
		

func _ready():
	if not OS.is_debug_build():
		call_deferred("queue_free")
	visible = false


func _input(event):
	if event is InputEventKey:
		var eventKey = event as InputEventKey
		if eventKey.keycode == KEY_F2 and eventKey.is_released():
			_toggle_visible()


func _toggle_visible():
	visible = not visible
	if visible:
		_refresh_contents()
		prev_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = prev_mouse_mode


func _refresh_contents():
	for item in items_v_box_container.get_children():
		item.queue_free()

	for task in get_tree().get_nodes_in_group(&"bug_marker"):
		task.connect(&"task_changed", _refresh_contents)
		var item = task_item_resource.instantiate()
		items_v_box_container.add_child(item)
		item.call_deferred("setup", task)
	

func _on_button_pressed():
	visible = false


func _on_type_option_button_item_selected(index):
	pass # Replace with function body.
