extends Node
class_name VoiceOrchestrator

signal received_voice_data
signal sent_voice_data
signal created_instance
signal removed_instance

@export var recording: bool = false: set = _set_recording
@export var listen: bool = false: set = _set_listen
@export var input_threshold: = 0.005: set = _set_input_threshold

#enum TypeVoiceInstance {NATIVE, GDSCRIPT}
#@export var type_voice_instance: TypeVoiceInstance

var instances := {}
var _id = null

func _ready() -> void:
	get_tree().get_multiplayer().connect("connected_to_server", Callable(self, "_connected_ok"))
	get_tree().get_multiplayer().connect("server_disconnected", Callable(self, "_server_disconnected"))
	get_tree().get_multiplayer().connect("connection_failed", Callable(self, "_server_disconnected"))

	get_tree().get_multiplayer().connect("peer_connected", Callable(self, "_player_connected"))
	get_tree().get_multiplayer().connect("peer_disconnected", Callable(self, "_player_disconnected"))

func _physics_process(delta: float) -> void:
	if get_tree().get_multiplayer().has_multiplayer_peer() && get_tree().get_multiplayer().is_server() && _id == null:
		_create_instance(get_tree().get_multiplayer().get_unique_id())

	if (!get_tree().get_multiplayer().has_multiplayer_peer() || !get_tree().get_multiplayer().is_server()) && _id == 1:
		_reset()

func _create_instance(id: int) -> void:
	var instance
	#if type_voice_instance == TypeVoiceInstance.NATIVE:
	#	instance = NativeVoiceInstance.new()
	#elif type_voice_instance == TypeVoiceInstance.GDSCRIPT:
	#	instance = VoiceInstance.new()
	instance = VoiceInstance.new()

	if id == get_tree().get_multiplayer().get_unique_id():
		instance.recording = recording
		instance.listen = listen
		instance.input_threshold = input_threshold

		instance.connect("sent_voice_data", Callable(self, "_sent_voice_data"))

		_id = id

	instance.connect("received_voice_data", Callable(self, "_received_voice_data"))

	instance.name = str(id)

	instances[id] = instance

	add_child(instance)

	emit_signal("created_instance", id)

func _remove_instance(id: int) -> void:
	var instance = instances[id]

	if id == _id:
		_id = null

	instance.queue_free()

	instances.erase(id)

	emit_signal("removed_instance", id)

func _reset() -> void:
	for id in instances.keys():
		_remove_instance(id)

func _set_recording(value: bool) -> void:
	if _id != null:
		instances[_id].recording = value

	recording = value

func _set_listen(value: bool) -> void:
	if _id != null:
		instances[_id].listen = value

	listen = value

func _set_input_threshold(value: float) -> void:
	if _id != null:
		instances[_id].input_threshold = value

	input_threshold = value

func _connected_ok() -> void:
	if (!get_tree().has_multiplayer_peer() || !get_tree().is_server()) && _id == 1:
		_reset()

	_create_instance(get_tree().get_unique_id())

func _server_disconnected() -> void:
	_reset()

func _player_connected(id) -> void:
	_create_instance(id)

func _player_disconnected(id) -> void:
	_remove_instance(id)

func _received_voice_data(data: PackedFloat32Array, id: int) -> void:
	emit_signal("received_voice_data", data, id)

func _sent_voice_data(data: PackedFloat32Array) -> void:
	emit_signal("sent_voice_data", data)
