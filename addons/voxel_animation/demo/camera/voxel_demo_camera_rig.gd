@tool
extends Node3D
class_name VoxelDemoCameraRig

## Minimal third-person orbit camera: mouse-look + scroll zoom.
## Self-contained so this demo has no dependency on any other addon.

@export_range(-90.0, 90.0, 0.1) var min_pitch_deg: float = -80.0
@export_range(-90.0, 90.0, 0.1) var max_pitch_deg: float = 10.0
@export_range(0.0, 0.02, 0.0001) var mouse_sensitivity: float = 0.005
@export var min_zoom: float = 2.0
@export var max_zoom: float = 12.0
@export var zoom_speed: float = 1.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clampf(spring_arm.spring_length - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clampf(spring_arm.spring_length + zoom_speed, min_zoom, max_zoom)
