@tool

extends Node

# Socket related signals

## A signal which is called when the connection was successfully established
signal connected

## A signal which is called when the connection was closed from the server or due to a disconnect
signal disconnected

# HypeRate related signals

## A signal which is called when a new channel was joined
signal channel_joined(channel_name: String)

## A signal which is called when a new heartbeat was received
signal heartbeat_received(channel_name: String, heartbeat: int)

## A signal which is called when a new clip has been created
signal clip_created(channel_name: String, twitch_slug: String)

## A signal which is called when a channel was successfully left
signal channel_left(channel_name: String)

var _websocket_client = WebSocketPeer.new()
var _channels: HypeRateChannels = HypeRateChannels.new()
var _hyperate_settings: HypeRateSettings = load("res://hyperate.tres")
var _last_state = WebSocketPeer.STATE_CLOSED

var _should_connect = false
var _should_disconnect = false

var _reconnect_timer = Timer.new()
var _heartbeat_timer = Timer.new()

# ----------
# Public API
# ----------

## Tells the socket to connect to the HypeRate server
## NOTE: This will not happen immediately
func connect_to_server() -> bool:
	var endpoint_url = _hyperate_settings.endpoint_url
	var token = _hyperate_settings.api_token

	if token == null or token.length() == 0:
		return false

	var cleaned_token = token.lstrip(" \t").rstrip(" \t")
	var real_url = _build_url(endpoint_url, cleaned_token)
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

## Tells the socket to reconnect to the HypeRate server
## NOTE: This will not happen immediately
func reconnect():
	if _should_disconnect == true:
		return

	if _reconnect_timer.is_stopped() == false:
		return

	_should_disconnect = true
	_reconnect_timer.start()

## Tries to join the heartbeat channel for the given device id / session id [br]
## It returns false when one of the following statements is true: [br]
## - the websocket connection is not open [br]
## - the channel is about to be joined (you have already called the join_heartbeat_channel function with the same ID but no response was received from the server yet) [br]
## - the channel has already been joined
func join_heartbeat_channel(device_id_or_session_id: String) -> bool:
	return _join_channel("hr:%s" % [device_id_or_session_id])

func leave_heartbeat_channel(device_id_or_session_id: String):
	return _leave_channel("hr:%s" % [device_id_or_session_id])

## Tries to join the clips channel for the given device id / session id [br]
## It returns false when one of the following statements is true: [br]
## - the websocket connection is not open [br]
## - the channel is about to be joined (you have already called the join_clips_channel function with the same ID but no response was received from the server yet) [br]
## - the channel has already been joined
func join_clips_channel(device_id_or_session_id: String) -> bool:
	return _join_channel("clips:%s" % [device_id_or_session_id])

func leave_clips_channel(device_id_or_session_id: String):
	return _leave_channel("clips:%s" % [device_id_or_session_id])

## Returns the type of the given channel name. [br]
## When the channel name starts with "hr:" then the [code]HypeRateChannels.ChannelType.Heartbeat[/code] enum member is returned. [br]
## When the channel name starts with "clips:" then the [code]HypeRateChannels.ChannelType.Clips[/code] enum member is returned. [br]
## In every other case the [code]HypeRateChannels.ChannelType.Unknown[/code] enum member is returned.
func get_channel_type(channel_name: String) -> HypeRateChannels.ChannelType:
	if channel_name.begins_with("hr:"):
		return HypeRateChannels.ChannelType.Heartbeat

	if channel_name.begins_with("clips:"):
		return HypeRateChannels.ChannelType.Clips

	return HypeRateChannels.ChannelType.Unknown

# ------------------
# Internal functions
# ------------------

func _join_channel(channel_name) -> bool:
	if _websocket_client.get_ready_state() != _websocket_client.STATE_OPEN:
		return false

	var join_ref = _channels.add_channel_to_join(channel_name)

	if join_ref == (-1):
		return false

	_websocket_client.send_text(HypeRateNetwork.join_channel_packet(channel_name, join_ref))

	return true

func _leave_channel(channel_name: String) -> bool:
	if _websocket_client.get_ready_state() != _websocket_client.STATE_OPEN:
		return false

	var leave_ref = _channels.leave_channel(channel_name)

	if leave_ref == (-1):
		return false

	_websocket_client.send_text(HypeRateNetwork.leave_channel_packet(channel_name, leave_ref))

	return true

func _ready():
	_reconnect_timer.wait_time = 5
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_on_reconnect)

	_heartbeat_timer.wait_time = _hyperate_settings.heartbeat_interval
	_heartbeat_timer.timeout.connect(_on_send_heartbeat)

	add_child(_reconnect_timer)
	add_child(_heartbeat_timer)

func _process(_delta):
	if _should_connect == false and _should_disconnect == false:
		return

	_websocket_client.poll()

	var current_state = _websocket_client.get_ready_state()

	if _websocket_client.get_available_packet_count() > 0:
		_process_packet(_websocket_client.get_packet())

	match [current_state, _last_state]:
		[_websocket_client.STATE_OPEN, _websocket_client.STATE_CONNECTING]:
			_rejoin_channels()
			_heartbeat_timer.start()
			connected.emit()
		[_websocket_client.STATE_OPEN, _websocket_client.STATE_CLOSED]:
			_rejoin_channels()
			_heartbeat_timer.start()
			connected.emit()
		[_websocket_client.STATE_CLOSED, _websocket_client.STATE_CLOSING]:
			_heartbeat_timer.stop()
			disconnected.emit()
		[_websocket_client.STATE_CLOSED, _websocket_client.STATE_OPEN]:
			_heartbeat_timer.stop()
			disconnected.emit()

	if current_state == _websocket_client.STATE_CLOSED and _should_connect == true:
		reconnect()

	if current_state == _websocket_client.STATE_CLOSED and _should_disconnect == true:
		_should_disconnect = false

	_last_state = current_state

## Internal callback when the reconnect timer reached its end
func _on_reconnect():
	connect_to_server()

## Internal callback when the heartbeat timer reached its end
func _on_send_heartbeat():
	if _websocket_client.get_ready_state() != _websocket_client.STATE_OPEN:
		return

	_websocket_client.send_text(HypeRateNetwork.keep_alive_packet())

## Internal callback when a new packet arrived
func _process_packet(packet: PackedByteArray):
	var read_packet = packet.get_string_from_utf8()
	var parsed_packet = JSON.parse_string(read_packet)

	if parsed_packet == null:
		print("Failed to parse packet: %s" % read_packet)
		return

	var topic = parsed_packet["topic"]
	var extracted_id: String

	match parsed_packet["event"]:
		"phx_reply":
			var phoenix_ref = parsed_packet["ref"]

			if phoenix_ref == 0:
				return

			var resolved_ref = _channels.get_reftype_by_ref(phoenix_ref)

			match resolved_ref:
				HypeRateChannels.RefType.Join:
					_channels.handle_join(phoenix_ref)

				HypeRateChannels.RefType.Leave:
					_channels.handle_leave(phoenix_ref)

				HypeRateChannels.RefType.Unknown:
					pass

		"hr_update":
			extracted_id = topic.substr(3, -1)
			heartbeat_received.emit(extracted_id, parsed_packet["payload"]["hr"])

		"clip:created":
			extracted_id = topic.substr(6, -1)
			clip_created.emit(extracted_id, parsed_packet["payload"]["twitch_slug"])

## Internal function to build the URL to connect to
func _build_url(endpoint_url: String, token: String) -> String:
	return "%s?token=%s" % [endpoint_url, token]

func _rejoin_channels():
	var channels_to_join = _channels.get_channels_to_join()

	_channels.handle_reconnect()

	for channel_to_join in channels_to_join:
		var generated_join_ref = _channels.add_channel_to_join(channel_to_join)

		_websocket_client.send_text(HypeRateNetwork.join_channel_packet(
			channel_to_join,
			generated_join_ref
		))
