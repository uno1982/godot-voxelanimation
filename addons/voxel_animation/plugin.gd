@tool
extends EditorPlugin

const SEQUENCE_SCRIPT := preload("res://addons/voxel_animation/scripts/voxel_animation_sequence.gd")
const LIBRARY_SCRIPT := preload("res://addons/voxel_animation/scripts/voxel_animation_library.gd")
const PLAYER_SCRIPT := preload("res://addons/voxel_animation/scripts/voxel_animation_player.gd")


func _enter_tree() -> void:
	add_custom_type("VoxelAnimationSequence", "Resource", SEQUENCE_SCRIPT, null)
	add_custom_type("VoxelAnimationLibrary", "Resource", LIBRARY_SCRIPT, null)
	add_custom_type("VoxelAnimationPlayer", "Node", PLAYER_SCRIPT, null)


func _exit_tree() -> void:
	remove_custom_type("VoxelAnimationSequence")
	remove_custom_type("VoxelAnimationLibrary")
	remove_custom_type("VoxelAnimationPlayer")
