@tool

extends Node

## A signal which is called when the connection was successfully established
signal socket_connected

## A signal which is called when a new channel was joined
signal channel_joined(channel_name: String)

## A signal which is called when a new heartbeat was received
signal heartbeat_received(channel_name: String, heartbeat: int)

## A signal which is called when a channel was successfully left
signal channel_left(channel_name: String)

## A signal which is called when the connection was closed from the server or due to a disconnect
signal socket_disconnected

var _websocket_client = WebSocketPeer.new()

var _channels = preload("res://addons/hyperate/channels.gd").new()

var _socket_settings = load("res://hyperate.tres")

var _last_state = WebSocketPeer.STATE_CLOSED
var _should_connect = false
var _should_disconnect = false

var _reconnect_timer = Timer.new()

var _heartbeat_timer = Timer.new()

## Tells the socket to connect to the HypeRate server
## NOTE: This will not happen immediately
func connect_to_server() -> bool:
	var endpoint_url = _socket_settings.get_meta("endpoint_url")
	var token = _socket_settings.get_meta("api_token")

	if token == null or token.length() == 0:
		return false

	var real_url = _build_url(endpoint_url, token)
	var error = _websocket_client.connect_to_url(real_url)

	if error:
		return false

	_should_connect = true
	_should_disconnect = false

	return true

## Tells the socket to disconnect from the HypeRate server
## NOTE: This will not happen immediately
func disconnect_from_server():
	_should_connect = false
	_should_disconnect = true
	_websocket_client.close()

func _ready():
	_reconnect_timer.wait_time = 5
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_on_reconnect)

	_heartbeat_timer.wait_time = _socket_settings.get_meta("heartbeat_interval")
	_heartbeat_timer.timeout.connect(_on_send_heartbeat)

	add_child(_reconnect_timer)
	add_child(_heartbeat_timer)

func _process(delta):
	if _should_connect == false and _should_disconnect == false:
		return

	_websocket_client.poll()

	var current_state = _websocket_client.get_ready_state()

	if _websocket_client.get_available_packet_count() > 0:
		_process_packet(_websocket_client.get_packet())

	match [current_state, _last_state]:
		[_websocket_client.STATE_OPEN, _websocket_client.STATE_CONNECTING]:
			_heartbeat_timer.start()
			socket_connected.emit()
		[_websocket_client.STATE_OPEN, _websocket_client.STATE_CLOSED]:
			_heartbeat_timer.start()
			socket_connected.emit()
		[_websocket_client.STATE_CLOSED, _websocket_client.STATE_CLOSING]:
			_heartbeat_timer.stop()
			socket_disconnected.emit()
		[_websocket_client.STATE_CLOSED, _websocket_client.STATE_OPEN]:
			_heartbeat_timer.stop()
			socket_disconnected.emit()

	if current_state == _websocket_client.STATE_CLOSED and _should_connect == true:
		reconnect()

	if current_state == _websocket_client.STATE_CLOSED and _should_disconnect == true:
		_should_disconnect = false

	_last_state = current_state

## Tells the socket to reconnect to the HypeRate server
## NOTE: This will not happen immediately
func reconnect():
	if _should_disconnect == true:
		return

	if _reconnect_timer.is_stopped() == false:
		return

	_should_disconnect = true
	_reconnect_timer.start()

## Internal callback when the reconnect timer reached its end
func _on_reconnect():
	print("Trying to reconnect to HypeRate")
	connect_to_server()

## Internal callback when the heartbeat timer reached its end
func _on_send_heartbeat():
	if _websocket_client.get_ready_state() != _websocket_client.STATE_OPEN:
		return

	print("Sending heartbeat to HypeRate")

	_websocket_client.send_text(JSON.stringify({
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": 0
	}))

## Internal callback when a new packet arrived
func _process_packet(packet : PackedByteArray):
	var read_packet = packet.get_string_from_utf8()
	var parsed_packet = JSON.parse_string(read_packet)

	if parsed_packet == null:
		print("Failed to parse packet: %s" % read_packet)
		return

	match parsed_packet["topic"]:
		"phoenix":
			print("Incoming system packet: %s" % parsed_packet)
		var topic:
			print("Incoming packet for topic: %s" % topic)

## Internal function to build the URL to connect to
func _build_url(endpoint_url: String, token : String) -> String:
	return "%s?token=%s" % [endpoint_url, token]
