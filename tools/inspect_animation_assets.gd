extends SceneTree
## Read-only inspection of the two Universal Animation Library Standard GLBs.
## Run from the project root after Godot has imported the assets:
## godot --headless --path . --script res://tools/inspect_animation_assets.gd
##
## Imp.glb and Puglin.glb are intentionally excluded.

const ASSET_PATHS := [
	"res://assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb",
	"res://assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard_RM.glb",
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
		"meshes": [],
		"materials": [],
		"skeletons": [],
		"animation_players": [],
	}
	if not ResourceLoader.exists(asset_path):
		result["load_error"] = "Resource not found. Open the project in the Godot editor and wait for import to finish."
		return result

	var packed := load(asset_path) as PackedScene
	if packed == null:
		result["load_error"] = "Resource did not load as PackedScene. Check the file's Import mode in Godot."
		return result

	var instance := packed.instantiate()
	if instance == null:
		result["load_error"] = "PackedScene.instantiate returned null."
		return result

	root.add_child(instance)
	_walk(instance, result)
	instance.queue_free()
	await process_frame
	return result

func _walk(node: Node, result: Dictionary) -> void:
	var type_name := node.get_class()
	var type_counts: Dictionary = result["node_types"]
	type_counts[type_name] = int(type_counts.get(type_name, 0)) + 1
	result["node_types"] = type_counts

	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var meshes: Array = result["meshes"]
		meshes.append({
			"node_path": str(mesh_node.get_path()),
			"mesh_resource": mesh_node.mesh.resource_name if mesh_node.mesh != null else "",
			"surface_count": mesh_node.mesh.get_surface_count() if mesh_node.mesh != null else 0,
		})
		result["meshes"] = meshes
		if mesh_node.mesh != null:
			for surface_index in range(mesh_node.mesh.get_surface_count()):
				var material := mesh_node.get_active_material(surface_index)
				if material != null:
					var materials: Array = result["materials"]
					var material_name := material.resource_name
					if material_name.is_empty():
						material_name = material.get_class()
					if not materials.has(material_name):
						materials.append(material_name)
					result["materials"] = materials

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
