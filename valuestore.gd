class_name Valuestore
extends Reference
# A simple class to store and retrieve loose values in JSON format


var _path: String = ''
var _data: Dictionary = {}
var _file_error: bool = false


func _init(path: String = _path):
	self._path = path
	self.load_data()


func is_valid() -> bool:
	return not self._file_error


func file_exists() -> bool:
	var file: File = File.new()
	return file.file_exists(self._path)


func load_data() -> void:
	var file: File = File.new()
	if not file.file_exists(self._path):
		return
	
	var res = file.open(self._path, File.READ)
	if res != OK:
		printerr('Could not open: %s' % self._path)
		self._file_error = true
		return
	
	var result: JSONParseResult = JSON.parse(file.get_as_text())
	if result.error != OK:
		printerr('Error parsing json for file: %s' % self._path)
		self._file_error = true
		return
	
	self._data = result.result
	file.close()


func put(key, value = null) -> void:
	if self._file_error:
		return
	
	var validated = self._validate_key(key)
	if not validated:
		printerr('Error: provided key (%s) is of an invalid type' % key)
		return
	
	if typeof(key) == TYPE_INT or typeof(key) == TYPE_REAL:
		key = String(key)

	var data = self.all()
	
	if typeof(key) == TYPE_DICTIONARY:
		var keys = key.keys()
		for k in keys:
			data[k] = key[k]
	else:
		data[key] = value
	
	self.save()


func put_object(obj) -> void:
	if self._file_error:
		return
	
	var result: JSONParseResult = JSON.parse(to_json(obj))
	if result.error != OK:
		printerr('Error parsing json for object: ')
		printerr(obj)
		printerr('Could not store object')
		self._file_error = true
		return
	
	self._data = obj
	self.save()


func save() -> void:
	if self._file_error:
		return
	
	var file: File = File.new()
	var res = file.open(self._path, File.WRITE)
	if res != OK:
		printerr('Error saving file: %s' % self._path)
	else:
		file.store_line(to_json(self.all()))
	
	file.close()


func retrieve(key: String, default = null, expected_type: int = -1):
	var all = self.all()
	var value = all.get(key, default)
	if expected_type != -1:
		var actual_type = typeof(value)
		
		if not typeof(value) == expected_type:
			
			if typeof(default) == expected_type:
				return default
			
			return null
	
	return value


func all() -> Dictionary:
	return self._data


func has(key: String) -> bool:
	return key in self.all().keys()


func forget(key: String) -> void:
	self.all().erase(key)
	self.save()


func flush() -> void:
	self._file_error = false
	self.put_object({})


func reset(default_data={}) -> void:
	self.flush()
	self.put_object(default_data)


const _allowed_key_types = [TYPE_STRING, TYPE_DICTIONARY, TYPE_INT, TYPE_REAL]
func _validate_key(key) -> bool:
	return typeof(key) in self._allowed_key_types
