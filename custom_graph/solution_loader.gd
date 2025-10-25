extends RefCounted
class_name SolutionLoader

const LEVELS_FOLDER = "res://Levels/"

# Load solutions for a specific level by name
func load_solutions_for_level(level_name: String) -> Array:
	var all_solutions: Array = []

	# Get all .solutions.json files
	var solution_files = get_solution_files_sorted()

	# Parse each file and extract solutions matching the level name
	for file_path in solution_files:
		var solutions_from_file = load_solutions_from_file(file_path, level_name)
		all_solutions.append_array(solutions_from_file)

	return all_solutions

func get_solution_files_sorted() -> Array[String]:
	var solution_files: Array[String] = []
	var dir = DirAccess.open(LEVELS_FOLDER)

	if dir == null:
		push_error("Failed to open Levels folder: " + LEVELS_FOLDER)
		return solution_files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".solutions.json"):
			solution_files.append(LEVELS_FOLDER + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort alphabetically
	solution_files.sort()

	return solution_files

func load_solutions_from_file(file_path: String, level_name: String) -> Array:
	var solutions: Array = []

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open solution file: " + file_path)
		return solutions

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse solution JSON in file: " + file_path)
		return solutions

	var data = json.data
	if not data is Dictionary or not data.has("solutions"):
		push_error("Invalid solution file format: " + file_path)
		return solutions

	# Filter solutions by level name
	for solution_data in data["solutions"]:
		if solution_data.get("level_name", "") == level_name:
			solutions.append(solution_data)

	print("Loaded %d solutions for level '%s' from %s" % [solutions.size(), level_name, file_path])

	return solutions
