extends CharacterBody3D
class_name VoxelDemoCharacter

## Minimal third-person controller demonstrating VoxelAnimationPlayer usage.
## Fully self-contained: registers its own default keybinds at runtime so this
## demo works immediately when the addon is dropped into a fresh project.

const MOVE_SPEED: float = 5.0
const ACCEL: float = 8.0
const DECEL: float = 7.5
const JUMP_VELOCITY: float = 4.5
const PUSH_STRENGTH: float = 8.0

@export var move_forward_action: StringName = &"voxel_demo_move_forward"
@export var move_backward_action: StringName = &"voxel_demo_move_backward"
@export var move_left_action: StringName = &"voxel_demo_move_left"
@export var move_right_action: StringName = &"voxel_demo_move_right"
@export var jump_action: StringName = &"voxel_demo_jump"

@onready var camera_rig: VoxelDemoCameraRig = $VoxelDemoCameraRig
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var animation_player: VoxelAnimationPlayer = $VoxelAnimationPlayer

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _last_state: StringName = &""


func _ready() -> void:
	mesh_instance.layers = 2 # kept off the Decal's cull_mask so decals don't project onto the character
	_register_default_actions()
	animation_player.play(&"Idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed(jump_action):
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector(move_left_action, move_right_action, move_forward_action, move_backward_action)
	var move_dir := (Vector3(input_dir.x, 0.0, input_dir.y)).rotated(Vector3.UP, camera_rig.global_rotation.y)

	if move_dir.length() > 0.0:
		velocity.x = lerp(velocity.x, move_dir.x * MOVE_SPEED, ACCEL * delta)
		velocity.z = lerp(velocity.z, move_dir.z * MOVE_SPEED, ACCEL * delta)
		var target_local_y := atan2(move_dir.x, move_dir.z) - global_rotation.y
		mesh_instance.rotation.y = lerp_angle(mesh_instance.rotation.y, target_local_y, 10.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECEL * delta)
		velocity.z = lerp(velocity.z, 0.0, DECEL * delta)

	move_and_slide()
	_push_rigid_bodies(delta)
	_update_animation_state(move_dir)


func _push_rigid_bodies(delta: float) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody3D:
			var push_dir: Vector3 = -collision.get_normal()
			push_dir.y = 0.0
			if push_dir.length() > 0.0:
				collider.apply_central_impulse(push_dir.normalized() * PUSH_STRENGTH * delta)


func _update_animation_state(move_dir: Vector3) -> void:
	var state: StringName
	if not is_on_floor():
		state = &"Jump"
	elif move_dir.length() > 0.0:
		state = &"Walk"
	else:
		state = &"Idle"

	if state != _last_state:
		animation_player.play(state)
		_last_state = state


func _register_default_actions() -> void:
	var defaults := {
		move_forward_action: [KEY_W, KEY_UP],
		move_backward_action: [KEY_S, KEY_DOWN],
		move_left_action: [KEY_A, KEY_LEFT],
		move_right_action: [KEY_D, KEY_RIGHT],
		jump_action: [KEY_SPACE],
	}
	for action: StringName in defaults:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode in defaults[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
