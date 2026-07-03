@tool
extends Resource
class_name VoxelAnimationLibrary

## Set of named voxel animation sequences, shareable across characters/scenes.
@export var sequences: Array[VoxelAnimationSequence] = []


func get_sequence(animation_name: StringName) -> VoxelAnimationSequence:
	for seq in sequences:
		if seq != null and seq.animation_name == animation_name:
			return seq
	return null


func has_animation(animation_name: StringName) -> bool:
	return get_sequence(animation_name) != null


func get_available_animations() -> Array[StringName]:
	var names: Array[StringName] = []
	for seq in sequences:
		if seq != null:
			names.append(seq.animation_name)
	return names
