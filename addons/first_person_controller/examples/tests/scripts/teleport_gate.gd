extends Area3D

@export var target: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	body.global_position = target.global_position	
