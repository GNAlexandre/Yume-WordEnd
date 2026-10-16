extends GutTest
## (F1) Aucun fichier du jeu ne cite un chemin disparu : chaque « res://… » écrit dans src/,
## data/ et tools/ (scripts, scènes, ressources, données, shaders, outils) nomme un fichier ou un
## dossier qui existe. Un chemin fabriqué (%s, {…}, *) n'est pas vérifié. Le retrait de l'ancienne
## île a supprimé des centaines de fichiers : une référence oubliée échouerait ici, et non au
## chargement d'une scène rarement ouverte.

const ROOTS: Array[String] = ["res://src", "res://data", "res://tools"]
const EXTENSIONS: Array[String] = [
	"gd", "tscn", "tres", "json", "gdshader", "gdshaderinc", "sh", "py", "js", "cfg"
]
## Chemins écrits exprès sans fichier derrière (sorties des outils, dossiers créés au besoin).
const ALLOWED_PREFIXES: Array[String] = ["res://build/", "res://build"]
## Exemples des modes d'emploi, et data/items (vide depuis F1 : les objets du récit y viendront).
const ALLOWED: Array[String] = ["res://scene.tscn", "res://chemin/scene.tscn", "res://data/items"]


func _files(dir: String, out: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			_files(dir.path_join(sub), out)
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in EXTENSIONS:
			out.append(dir.path_join(file))


func _exists(path: String) -> bool:
	return (
		FileAccess.file_exists(path)
		or DirAccess.dir_exists_absolute(path)
		or ResourceLoader.exists(path)
	)


func test_every_written_path_exists() -> void:
	var files: Array[String] = []
	for root: String in ROOTS:
		_files(root, files)
	assert_gt(files.size(), 500, "les fichiers du jeu")
	var pattern := RegEx.create_from_string("res://[A-Za-z0-9_./-]+")
	var dead: Array[String] = []
	for file: String in files:
		var text := FileAccess.get_file_as_string(file)
		for found: RegExMatch in pattern.search_all(text):
			var path := found.get_string().trim_suffix(".").trim_suffix("/")
			# Chemin fabriqué : la suite est un gabarit (%s, {id}, *, <carte>, $VAR).
			if text.substr(found.get_end(), 1) in ["%", "{", "*", "<", "$"]:
				continue
			if ALLOWED_PREFIXES.any(func(prefix: String) -> bool: return path.begins_with(prefix)):
				continue
			if path in ALLOWED or path.ends_with("_") or path.ends_with("-"):
				continue
			if not _exists(path):
				dead.append("%s : %s" % [file, path])
	assert_eq(dead, [] as Array[String], "chemins disparus :\n%s" % "\n".join(dead))
