@tool
extends Resource
class_name VoxelAnimationSequence

enum PlayMode { LOOP, ONCE, PING_PONG }

## Name this sequence is looked up by (e.g. "Idle", "Walk", "Jump").
@export var animation_name: StringName = &""

## Ordered list of imported mesh scenes (e.g. glTF/glb exports), one per frame.
## Each scene's first MeshInstance3D's mesh is extracted at runtime/edit-time.
@export var frames: Array[PackedScene] = []

@export_range(1.0, 60.0, 1.0) var frame_rate: float = 12.0

@export var play_mode: PlayMode = PlayMode.LOOP

@export var autoplay: bool = true

var _mesh_cache: Array[Mesh] = []


func get_frame_count() -> int:
	return frames.size()


func get_duration() -> float:
	if frame_rate <= 0.0:
		return 0.0
	return frames.size() / frame_rate


func get_frame_mesh(index: int) -> Mesh:
	if index < 0 or index >= frames.size():
		return null
	while _mesh_cache.size() < frames.size():
		_mesh_cache.append(null)
	if _mesh_cache[index] == null:
		_mesh_cache[index] = _extract_mesh(frames[index])
	return _mesh_cache[index]


func _extract_mesh(scene: PackedScene) -> Mesh:
	if scene == null:
		return null
	var instance := scene.instantiate()
	var mesh_instance := _find_mesh_instance(instance)
	var mesh: Mesh = mesh_instance.mesh if mesh_instance != null else null
	instance.free()
	return mesh


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null
