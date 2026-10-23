extends SceneTree
## Read-only diagnostic for the Universal Animation Library and candidate character GLBs.
## Run after Godot has imported the project:
## godot --headless --path . --script res://tools/inspect_animation_assets.gd

const ASSET_PATHS := [
	"res://assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb",
	"res://assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard_RM.glb",
	"res://assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Imp.glb",
	"res://assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Puglin.glb",
]

func _initialize() -> void:
	call_deferred("_inspect_all")

func _inspect_all() -> void:
	var report: Array[Dictionary] = []
	for asset_path in ASSET_PATHS:
		report.append(_inspect_scene(asset_path))
	print("ANIMATION_ASSET_DIAGNOSTIC_BEGIN")
	print(JSON.stringify(report, "\t"))
	print("ANIMATION_ASSET_DIAGNOSTIC_END")
	quit(0)

func _inspect_scene(asset_path: String) -> Dictionary:
	var result: Dictionary = {
		"path": asset_path,
		"exists": ResourceLoader.exists(asset_path),
		"load_error": "",
		"node_types": {},
		"skeletons": [],
		"animation_players": [],
	}
	if not ResourceLoader.exists(asset_path):
		result["load_error"] = "ResourceLoader.exists returned false. Run editor import first and verify the path."
		return result

	var packed := load(asset_path) as PackedScene
	if packed == null:
		result["load_error"] = "Resource could not be loaded as PackedScene."
		return result

	var instance := packed.instantiate()
	if instance == null:
		result["load_error"] = "PackedScene.instantiate returned null."
		return result

	_walk(instance, result)
	instance.free()
	return result

func _walk(node: Node, result: Dictionary) -> void:
	var type_name := node.get_class()
	var type_counts: Dictionary = result["node_types"]
	type_counts[type_name] = int(type_counts.get(type_name, 0)) + 1
	result["node_types"] = type_counts

	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		var bones: Array[Dictionary] = []
		for bone_index in range(skeleton.get_bone_count()):
			bones.append({
				"index": bone_index,
				"name": skeleton.get_bone_name(bone_index),
				"parent": skeleton.get_bone_parent(bone_index),
			})
		var skeletons: Array = result["skeletons"]
		skeletons.append({
			"node_path": str(node.get_path()),
			"bone_count": skeleton.get_bone_count(),
			"bones": bones,
		})
		result["skeletons"] = skeletons

	if node is AnimationPlayer:
		var player := node as AnimationPlayer
		var clips: Array[Dictionary] = []
		for clip_name in player.get_animation_list():
			var animation := player.get_animation(clip_name)
			clips.append({
				"name": clip_name,
				"duration_seconds": animation.length if animation != null else -1.0,
				"track_count": animation.get_track_count() if animation != null else -1,
			})
		var players: Array = result["animation_players"]
		players.append({
			"node_path": str(node.get_path()),
			"root_node": str(player.root_node),
			"clips": clips,
		})
		result["animation_players"] = players

	for child in node.get_children():
		_walk(child, result)
