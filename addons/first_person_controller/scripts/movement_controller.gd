extends CharacterBody3D
class_name MovementController

@export var gravity_multiplier := 3.0
@export var speed := 10
@export var acceleration := 8
@export var deceleration := 10
@export_range(0.0, 1.0, 0.05) var air_control := 0.3
@export var jump_height: float = 2
@export var jump_timeout_sec: float = 0.5

## Only jump when just pressed if true. If false, keep jumping while jump key held down.
@export var jump_on_just_pressed = true
## Allow jumping while sliding down a steep slope.
@export var slide_jump_enabled = true
## Allow jumping against walls.
@export var wall_jump_enabled = true
## Max angle in degrees between wall and forward vector of character that allows a wall jump.
@export_range(0, 180) var max_wall_jump_angle = 120
## How to handle slide / wall jumps. RESET_VELOCITY will set the character velocity to the jump velocity projected on the wall normal. ADD_VELOCITY will add the jump velocity projected on the wall normal to the character velocity. GAIN_HEIGHT will set only the y component of the character velocity to the jump velocity.
@export var wall_jump_mode = Wall_Jump_Modes.RESET_VELOCITY
@export var height: float = 1.8
@export var radius: float = 0.3
@export var head_offset: float = 0.25
@onready var foot_offset: float = height / 2
var direction := Vector3()
var input_axis := Vector2()
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") 
		* gravity_multiplier)
@onready var next_jump_time: float = Time.get_ticks_msec()
var collision_shape: CollisionShape3D

enum Wall_Jump_Modes {
	RESET_VELOCITY,
	ADD_VELOCITY,
	GAIN_HEIGHT
}

func _ready():
	set_up_collision()
	
func set_up_collision() -> void:
	var collision = get_node("Collision")
	if collision is CollisionShape3D:
		var shape = collision.shape
		if shape is CapsuleShape3D:
			var capsule = shape as CapsuleShape3D
			capsule.height = height
			capsule.radius = radius
			collision.position = Vector3(0, height / 2, 0)
	else:
		push_error("Could not find Collision node with a capsule shape")
	var head = get_node("Head")
	head.position = Vector3(0, height - head_offset, 0)
			
# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	input_axis = Input.get_vector(&"move_back", &"move_forward",
			&"move_left", &"move_right")
	
	direction_input()
	
	if is_on_floor():
		if jump_input():
			add_jump_velocity(jump_height)
	elif is_jumping_against_wall():
#	elif is_sliding_down_slope() and jump_input() and slide_jump_enabled:
		add_slope_jump_velocity(jump_height)
	else:
		velocity.y -= gravity * delta
	
	accelerate(delta)
	
	move_and_slide()

func jump_input() -> bool:
	var pressed = false
	if jump_on_just_pressed:
		if Input.is_action_just_pressed(&"jump"):
			pressed = true
	elif Input.is_action_pressed(&"jump"):
		pressed = true
	var now = Time.get_ticks_msec()
	if now >= next_jump_time and pressed:
		next_jump_time = now + jump_timeout_sec * 1000
		return true
	return false
	
func add_jump_velocity(jump_height: float) -> void:
	velocity.y = sqrt(2 * jump_height * gravity)
	
func add_slope_jump_velocity(jump_height: float) -> void:
	var v : Vector3
	var jump_speed = sqrt(2 * jump_height * gravity)
	var jumpVel = 	jump_speed * get_wall_normal()
	if wall_jump_mode == Wall_Jump_Modes.RESET_VELOCITY:
		v = jump_speed * get_wall_normal()	
	elif wall_jump_mode == Wall_Jump_Modes.ADD_VELOCITY:
		v = get_real_velocity() + jump_speed * get_wall_normal()	
	elif wall_jump_mode == Wall_Jump_Modes.GAIN_HEIGHT:
		v = get_real_velocity()
		#TODO - change implementation. Make v.y = 0. Add a jump velocity that has a horizontal component against wall direction. Maybe make magnitude of hor. component proportional to an exported variable.
		v.y = jump_speed
	velocity = v

func is_jumping_against_wall() -> bool:
	if is_on_wall_only() and jump_input():
		return is_stepping_on_wall() or is_touching_wall_ahead()
	return false

func is_stepping_on_wall() -> bool:
	return get_wall_normal().dot(up_direction) > 0

func is_touching_wall_ahead() -> bool:
	var facing_away_dir = global_transform.basis.z
	# TODO: take into account max_wall_jump_angle instead of hardcoding to 90 degress
	var max_angle_rad = deg_to_rad(max_wall_jump_angle)
	return get_wall_normal().dot(facing_away_dir) > cos(max_angle_rad)

func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	direction = aim.z * -input_axis.x + aim.x * input_axis.y


func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0
	
	var temp_accel: float
	var target: Vector3 = direction * speed
	
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration
	
	if not is_on_floor():
		temp_accel *= air_control
	
	temp_vel = temp_vel.lerp(target, temp_accel * delta)
	
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	
func get_foot_pos() -> Vector3:
	return global_position
	
