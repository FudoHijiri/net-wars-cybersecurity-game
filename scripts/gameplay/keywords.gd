class_name Keywords
extends RefCounted
## The glossary of the cards (data/keywords.json): the words of a card text that need a short explanation.
## highlight() gives the text as BBCode with each such word in color and as a link (the link target is the
## keyword id), so a RichTextLabel can tell which word the mouse is on (meta_hover_started) and the
## caller can show explain(id).

const PATH := "res://data/keywords.json"

static var _table: Dictionary = {}
static var _regex: RegEx
static var _word_to_id: Dictionary = {}


static func _load() -> void:
	if not _table.is_empty():
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Keywords: cannot open %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var words: Array[String] = []
	for id: String in parsed:
		if id.begins_with("_"):
			continue
		_table[id] = parsed[id]
		for word: String in parsed[id].get("words", []):
			_word_to_id[word.to_lower()] = id
			words.append(word)
	_regex = RegEx.create_from_string("(?i)\\b(%s)\\b" % "|".join(words))


## {name, color, text, words} of a keyword, or an empty Dictionary.
static func explain(id: String) -> Dictionary:
	_load()
	return _table.get(id, {})


## The color of a keyword: the one the player chose for its role (Settings > Custom Colors) when it has a
## "role" in the file, else its own "color".
static func color_of(id: String) -> Color:
	_load()
	var entry: Dictionary = _table.get(id, {})
	if entry.has("role"):
		return GameColors.color(StringName(str(entry["role"])))
	return Color(str(entry.get("color", "#ffffff")))


## The ids of the keywords in a text, in the order they first appear, each once.
static func ids_in(text: String) -> Array[String]:
	_load()
	var found: Array[String] = []
	if _regex == null:
		return found
	for match: RegExMatch in _regex.search_all(text):
		var id: String = _word_to_id[match.get_string().to_lower()]
		if not found.has(id):
			found.append(id)
	return found


## The text as BBCode: every keyword in its color, as a link to its id. Everything else is left as it was
## (a "[" in the text is escaped, so it is not read as a tag).
static func highlight(text: String) -> String:
	_load()
	var plain := text.replace("[", "[lb]")
	if _regex == null:
		return plain
	var out := ""
	var at := 0
	for match: RegExMatch in _regex.search_all(plain):
		var id: String = _word_to_id[match.get_string().to_lower()]
		out += plain.substr(at, match.get_start() - at)
		out += "[url=%s][color=#%s]%s[/color][/url]" % [id, color_of(id).to_html(false), match.get_string()]
		at = match.get_end()
	return out + plain.substr(at)
