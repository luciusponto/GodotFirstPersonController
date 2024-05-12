@tool
extends Control

signal select_requested(node_instanceid: int)

const BUG_MARKER = preload("res://addons/scene_task_tracker/task_marker.gd")

var task_instance_id: int
var task_priority: int

func setup(target_task):
	var task = target_task as BUG_MARKER
	task_instance_id = task.get_instance_id()
	%DescriptionButton.text = task.description
	%DescriptionButton.tooltip_text = task.description
	%TaskTypeIcon.texture = task.get_icon()
	%TaskTypeIcon.modulate = task.get_color()
	%FixedCheckBox.button_pressed = task.fixed
	%PriorityLabel.text = str(task.priority)
	task_priority = task.priority

func _on_description_button_pressed():
	select_requested.emit(task_instance_id)
