extends Control

@onready var buttonServer: Button = $MarginContainer/HBoxContainer/VBoxContainer/Server
@onready var buttonClient: Button = $MarginContainer/HBoxContainer/VBoxContainer/Client
@onready var buttonVoice : Button = $MarginContainer/HBoxContainer/VBoxContainer/Voice
@onready var buttonDisconnect : Button = $MarginContainer/HBoxContainer/VBoxContainer/Disconnect

@onready var optionButtonServerType: OptionButton = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer5/ServerType
@onready var optionButtonVoiceType: OptionButton = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer6/VoiceType
@onready var spinBoxHostPort: SpinBox = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Port
@onready var lineEditClientIp: LineEdit = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer1/Ip
@onready var spinBoxClientPort: SpinBox = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/Port
@onready var checkboxListen: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer4/Listen
@onready var checkBoxToggle: CheckBox = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer4/Toggle
@onready var sliderInputThreshold: HSlider = $MarginContainer/HBoxContainer/VBoxContainer/InputThreshold

@onready var labelStatus: Label = $MarginContainer/HBoxContainer/Control/VBoxContainer2/HBoxContainer/Status
@onready var labelLog: RichTextLabel = $MarginContainer/HBoxContainer/Control/VBoxContainer2/Log
@onready var spinBoxInputThreshold: SpinBox = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Value

@onready var voice: VoiceOrchestrator = $VoiceOrchestrator
@onready var network: Network = $Network

func _ready() -> void:
	voice.connect("received_voice_data", Callable(self, "_received_voice_data"))
	voice.connect("sent_voice_data", Callable(self, "_sent_voice_data"))

	get_tree().connect("connected_to_server", Callable(self, "_connected_ok"))
	get_tree().connect("server_disconnected", Callable(self, "_server_disconnected"))
	get_tree().connect("connection_failed", Callable(self, "_connected_fail"))

	get_tree().connect("peer_connected", Callable(self, "_player_connected"))
	get_tree().connect("peer_disconnected", Callable(self, "_player_disconnected"))

	if voice.recording:
		checkBoxToggle.button_pressed = true
		buttonVoice.button_pressed = true

	for i in network.ClientType.values():
		var type_name: String = network.ClientType.keys()[i]
		type_name = type_name.substr(0, 1) + type_name.substr(1).to_lower()
		optionButtonServerType.add_item(type_name, i)

	for i in voice.TypeVoiceInstance.values():
		var type_name: String = voice.TypeVoiceInstance.keys()[i]
		type_name = type_name.substr(0, 1) + type_name.substr(1).to_lower()
		optionButtonVoiceType.add_item(type_name, i)

	optionButtonServerType.selected = network.client_type
	optionButtonVoiceType.selected = voice.type_voice_instance
	spinBoxHostPort.value = network.server_port
	lineEditClientIp.text = network.server_ip
	spinBoxClientPort.value = network.server_port
	checkboxListen.button_pressed = voice.listen
	checkBoxToggle.button_pressed = buttonVoice.toggle_mode
	sliderInputThreshold.value = voice.input_threshold

func _on_Button_server_pressed() -> void:
	var err = network.start_server()
	if err != OK:
		labelStatus.text = "Failed to create server! Error: %s" % err

		if err == FAILED && OS.get_name() == "HTML5":
			labelStatus.text += ", Starting a server is not supported on HTML5."

		return

	labelStatus.text = "Server started"

	ui_transition()

func _on_Button_client_pressed() -> void:
	var err = network.start_client()
	if err != OK:
		labelStatus.text = "Failed to create client! Error: %s" % err
		return

	labelStatus.text = "Connecting..."

func _on_Disconnect_pressed() -> void:
	network.stop()
	labelStatus.text = "Connection stopped"
	ui_reset()

func _on_Button_voice_button_down() -> void:
	if !buttonVoice.toggle_mode:
		voice.recording = true

func _on_Button_voice_button_up() -> void:
	if !buttonVoice.toggle_mode:
		voice.recording = false

func _on_Voice_toggled(button_pressed: bool) -> void:
	voice.recording = button_pressed

func _on_Toggle_toggled(button_pressed: bool) -> void:
	buttonVoice.toggle_mode = button_pressed

func _on_Listen_toggled(button_pressed: bool) -> void:
	voice.listen = button_pressed

func _on_InputThreshold_value_changed(value: float) -> void:
	voice.input_threshold = value
	spinBoxInputThreshold.value = value

func _on_Value_value_changed(value: float) -> void:
	sliderInputThreshold.value = value

func _on_Port_value_changed(value: float) -> void:
	network.server_port = int(value)

func _on_Ip_text_changed(new_text: String) -> void:
	network.server_ip = new_text

func _connected_ok() -> void:
	labelStatus.text = "Connected ok"
	ui_transition()

func _connected_fail() -> void:
	labelStatus.text = "Failed to connect to server!"
	ui_reset()

func _server_disconnected() -> void:
	labelStatus.text = "Server disconnected"
	ui_reset()

func _player_connected(_id: int) -> void:
	labelLog.text += "Player with id: %s connected\\n" % _id

func _player_disconnected(_id: int) -> void:
	labelLog.text += "Player with id: %s disconnected\\n" % _id

func _received_voice_data(data: PackedFloat32Array, id: int) -> void:
	labelLog.add_text("Received voice data of size:%s from id:%s\\n" % [data.size(), id])

func _sent_voice_data(data: PackedFloat32Array) -> void:
	labelLog.add_text("Sent voice data of size:%s\\n" % data.size())


func ui_transition() -> void:
	optionButtonServerType.disabled = true
	optionButtonVoiceType.disabled = true
	buttonServer.disabled = true
	buttonClient.disabled = true
	buttonVoice.disabled = false
	buttonDisconnect.disabled = false
	checkboxListen.disabled = false
	checkBoxToggle.disabled = false
	sliderInputThreshold.editable = true
	spinBoxInputThreshold.editable = true
	spinBoxHostPort.editable = false
	lineEditClientIp.editable = false
	spinBoxClientPort.editable = false

func ui_reset() -> void:
	optionButtonServerType.disabled = false
	optionButtonVoiceType.disabled = false
	buttonServer.disabled = false
	buttonClient.disabled = false
	buttonVoice.disabled = true
	buttonDisconnect.disabled = true
	checkboxListen.disabled = true
	checkBoxToggle.disabled = false
	buttonVoice.button_pressed = false
	sliderInputThreshold.editable = false
	spinBoxInputThreshold.editable = false
	spinBoxHostPort.editable = true
	lineEditClientIp.editable = true
	spinBoxClientPort.editable = true

func _on_ServerType_item_selected(index: int) -> void:
	network.client_type = index

func _on_VoiceType_item_selected(index: int) -> void:
	voice.type_voice_instance = index
