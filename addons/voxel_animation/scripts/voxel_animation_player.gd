@tool
extends Node
class_name VoxelAnimationPlayer

## Ticks a timer and swaps whole meshes on a target MeshInstance3D per frame -
## the 3D equivalent of a 2D sprite-sheet flipbook. Runs in-editor (@tool) so
## dragging a library/target or scrubbing `current_frame` previews live in the
## viewport without pressing play.

signal animation_state_changed(old_animation: StringName, new_animation: StringName)
signal animation_finished(completed_animation: StringName)
signal frame_changed(old_frame: int, new_frame: int)

@export var library: VoxelAnimationLibrary:
	set(value):
		library = value
		_refresh_preview()

@export var target_mesh_instance: MeshInstance3D:
	set(value):
		target_mesh_instance = value
		_refresh_preview()

@export var autostart_animation: StringName = &"Idle"
@export var autostart: bool = true

@export var is_playing: bool = false:
	set(value):
		is_playing = value
		notify_property_list_changed()

@export_range(0.0, 1.0) var animation_alpha: float = 0.0
@export var current_frame_index: int = 0:
	set(value):
		_set_frame(value)
	get:
		return _current_frame_index

var _current_frame_index: int = 0

var current_animation: StringName = &""
var playback_speed_multiplier: float = 1.0

var _frame_timer: float = 0.0
var _is_paused: bool = false
var _reverse_playback: bool = false
var _current_sequence: VoxelAnimationSequence


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_preview()
		return
	if autostart and library != null and library.has_animation(autostart_animation):
		play(autostart_animation)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_playing or _is_paused or _current_sequence == null:
		return
	_advance(delta)


func play(animation_name: StringName, force_restart: bool = false) -> void:
	if library == null:
		push_warning("VoxelAnimationPlayer: no library assigned")
		return
	var seq := library.get_sequence(animation_name)
	if seq == null:
		push_warning("VoxelAnimationPlayer: animation '%s' not found in library" % animation_name)
		return
	if seq == _current_sequence and not force_restart:
		is_playing = true
		_is_paused = false
		return

	var old_animation := current_animation
	_current_sequence = seq
	current_animation = animation_name
	_frame_timer = 0.0
	_reverse_playback = false
	is_playing = true
	_is_paused = false
	_set_frame(0)
	animation_state_changed.emit(old_animation, current_animation)


func stop() -> void:
	is_playing = false
	_is_paused = false
	_frame_timer = 0.0


func pause(should_pause: bool) -> void:
	_is_paused = should_pause


func set_playback_speed(speed: float) -> void:
	playback_speed_multiplier = speed


func get_current_animation_frame_count() -> int:
	return _current_sequence.get_frame_count() if _current_sequence != null else 0


func get_current_animation_duration() -> float:
	return _current_sequence.get_duration() if _current_sequence != null else 0.0


func _advance(delta: float) -> void:
	var frame_count := _current_sequence.get_frame_count()
	if frame_count <= 0:
		return

	_frame_timer += delta * _current_sequence.frame_rate * playback_speed_multiplier
	if _frame_timer < 1.0:
		animation_alpha = _frame_timer
		return

	while _frame_timer >= 1.0:
		_frame_timer -= 1.0
		_step_frame(frame_count)
	animation_alpha = _frame_timer


func _step_frame(frame_count: int) -> void:
	match _current_sequence.play_mode:
		VoxelAnimationSequence.PlayMode.LOOP:
			_set_frame((current_frame_index + 1) % frame_count)
		VoxelAnimationSequence.PlayMode.ONCE:
			if current_frame_index >= frame_count - 1:
				is_playing = false
				animation_finished.emit(current_animation)
			else:
				_set_frame(current_frame_index + 1)
		VoxelAnimationSequence.PlayMode.PING_PONG:
			var next := current_frame_index + (-1 if _reverse_playback else 1)
			if next >= frame_count - 1:
				next = frame_count - 1
				_reverse_playback = true
			elif next <= 0:
				next = 0
				_reverse_playback = false
			_set_frame(next)


func _set_frame(index: int) -> void:
	var old_frame := _current_frame_index
	_current_frame_index = index
	_apply_mesh_for_frame()
	if old_frame != index:
		frame_changed.emit(old_frame, index)


func _apply_mesh_for_frame() -> void:
	if target_mesh_instance == null or _current_sequence == null:
		return
	var frame_count := _current_sequence.get_frame_count()
	if frame_count <= 0:
		return
	var clamped := clampi(current_frame_index, 0, frame_count - 1)
	target_mesh_instance.mesh = _current_sequence.get_frame_mesh(clamped)


func _refresh_preview() -> void:
	if not Engine.is_editor_hint():
		return
	if library == null:
		return
	var seq := library.get_sequence(autostart_animation)
	if seq == null and not library.sequences.is_empty():
		seq = library.sequences[0]
	_current_sequence = seq
	_apply_mesh_for_frame()
