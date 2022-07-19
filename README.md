# Godot Valuestore

A simple class to store and retrieve loose values in JSON format, inspired by [spatie/valuestore](https://github.com/spatie/valuestore)

Usage:

```gdscript
# In your main file/wherever you want

# If the specified path does not exist, it will be created the first time a new value is added using the `put` method
var valuestore: Valuestore = Valuestore.new('user://settings.json')

# accepted key types: [TYPE_STRING, TYPE_INT, TYPE_REAL, TYPE_DICTIONARY]
valuestore.put('key', 'value')
valuestore.put(1, 'value')
valuestore.put(1.5, 'value')
valuestore.put({
    'key': 'value',
    'fun_fact': 'Sloths are pretty cool'
})

valuestore.put_object({}) # Put an entire object into the data file, replacing all existing data

valuestore.retrieve('key') # Returns 'value'
valuestore.retrieve('invalid_key') # Returns null
valuestore.retrieve('invalid_key', 'default') # Returns 'default'

# Retrieve with type checks to avoid crashes.
# Note: the default value provided must also match the expected type,
# or a null value will be returned
# Example data: { 'some_boolean': true }
valuestore.retrieve('some_boolean', false, TYPE_BOOL) # Returns true

# Example data: { 'some_boolean': 123 }
valuestore.retrieve('some_boolean', false, TYPE_BOOL) # Returns false

# Example data: { 'some_int': 'Hello, World!' }
valuestore.retrieve('some_int', 0, TYPE_INT) # Returns 0

valuestore.has('key') # Returns true

valuestore.all() # Returns the raw GDScript Dictionary object

valuestore.forget('key') # Removes the key

valuestore.flush() # Clears all data

valuestore.reset({'default_key': 'value'}) # Clears all data and puts the provided default data
```

## A note on value comparisons
```gdscript
# Due to how GDScript comparisons work, if you want to compare a value of a retrieved key
# (which you probably will), it is recommended to pass in a third parameter to retrieve(): 'expected_type'
# Without this, comparisons of mismatched types will cause Godot to crash.

# For example, the following code will not check that 'some_boolean' is true, but rather that is resolves to
# a truthy value, meaning any value including numbers or strings will resolve to true:
# Example data: { 'some_boolean': 1.0 }
if valuestore.retrieve('some_boolean'):
    # We expect the value to be 'true', but it could be any truthy value
    print('some_boolean is true!')

# As a result of this, if we were to do a comparison using retrieve() and the value was not
# of the same type as the value we are comparing against, Godot will crash.
# Example data: { 'some_boolean': 100.0 }
if valuestore.retrieve('some_boolean') == true: # GDScript will throw an error here
    print('some_boolean is true!')

# To properly ensure a value is what we expect, either manually check the type yourself using typeof(), 
# or pass an additional 'expected_type' parameter in:
if valuestore.retrieve('some_boolean', false, TYPE_BOOL):
    # Valuestore will perform a type check to avoid Godot crashing
    # If the types do not match, the provided default is returned, or null
    print('some_boolean is true!')
```

## Important note about JSON serialization

Valuestore uses the built-in [`to_json(Variant var)`](https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-to-json) serialization method to store data. From the GDScript docs:

`Note: The JSON specification does not define integer or float types, but only a number type. Therefore, converting a Variant to JSON text will convert all numerical values to float types.`

## Usage

Import valuestore.gd into your project. To create a new instance, use the `new` method.

```gdscript
var valuestore: Valuestore = Valuestore.new('user://settings.json')
```

## Handling corrupt data

While Valuestore is not meant to be used as a data storage system for complex save game data, multi-level JSON data, or anything too important for your project, it can still be used for simple things such as:
- Basic settings/config files
- Basic, single-layer user profile data
- Random loose data that isn't tied to anything specific

If you are storing any data that may alter the functionality of your application/game in the event of invalid data, it is important to handle the event where the JSON parse fails:
```gdscript
# Ideally you would put this in a singleton in your project to avoid having to check in multiple places during scene changes.
# We can check if our settings file is valid, and if not, flush and reset it to default values

var valuestore: Valuestore

func _ready() -> void:
    self.valuestore = Valuestore.new('user://settings.json')

    if not self.valuestore.is_valid():
        var default_data = {
            'Hello': 'world!'
        }
        self.valuestore.reset(default_data)
```

Note that `valuestore.is_valid()` will not return `false` if the file does not exist - only if the file *does* exist, but it failed to parse the data inside. If you want to check if the file exists, you can use the `file_exists()` method after creating a new `Valuestore` instance.

```gdscript
var valuestore: Valuestore

func _ready() -> void:
    self.valuestore = Valuestore.new('user://settings.json')

    if not self.valuestore.file_exists():
        var default_data = {
            'Hello': 'world!'
        }
        self.valuestore.reset(default_data)
```

## Real world example

The following is an example of how you might use Valuestore to manage a basic game config or settings file, and show a custscene if the game is being loaded for the first time. This example makes use of a `Game.gd` script being autoloaded as a singleton before any other scripts.

`Game.gd`
```gdscript
extends Node
# Game manager autoload singleton, loaded before everything else


var settings: Valuestore
const DEFAULT_SETTINGS: Dictionary = {
	'initial_cutscene_shown': false
}


func _ready() -> void:
	settings = Valuestore.new('user://settings.json')
	
    if not settings.is_valid() or not settings.file_exists():
		settings.reset(DEFAULT_SETTINGS)
	
    var initial_cutscene_shown = settings.retrieve('initial_cutscene_shown', false, TYPE_BOOL)
	if not initial_cutscene_shown:
		show_initial_cutscene()
	
	# Load the rest of the game here, or via a signal, etc..


func show_initial_cutscene():
	print('Showing cutscene for the first time...')
	
	settings.put('initial_cutscene_shown', true)
```


## Inspiration

- [spatie/valuestore](https://github.com/spatie/valuestore)

## License

MIT License (MIT). Please view [LICENSE](LICENSE) for more information.
