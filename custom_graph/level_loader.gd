extends RefCounted
class_name LevelLoader

const LEVELS_FOLDER = "res://Levels/"

func load_all_levels() -> Array:
	var all_levels: Array = []

	# Get all JSON files in Levels folder
	var json_files = get_json_files_sorted()

	# Parse each file
	for file_path in json_files:
		var levels_from_file = load_levels_from_file(file_path)
		all_levels.append_array(levels_from_file)

	return all_levels

func get_json_files_sorted() -> Array[String]:
	var json_files: Array[String] = []
	var dir = DirAccess.open(LEVELS_FOLDER)

	if dir == null:
		push_error("Failed to open Levels folder: " + LEVELS_FOLDER)
		return json_files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			json_files.append(LEVELS_FOLDER + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort alphabetically
	json_files.sort()

	return json_files

func load_levels_from_file(file_path: String) -> Array:
	var levels: Array = []

	# Read file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + file_path)
		return levels

	var json_text = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		push_error("Failed to parse JSON in file: " + file_path + " at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return levels

	var data = json.data

	# Expect array of level objects
	if not data is Array:
		push_error("JSON root must be an array in file: " + file_path)
		return levels

	# Parse each level
	for level_data in data:
		if level_data is Dictionary:
			levels.append(LevelData.new(level_data))
		else:
			push_warning("Skipping non-dictionary level in file: " + file_path)

	return levels
