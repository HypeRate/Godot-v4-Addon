extends Node2D

var _join_channel_timer = Timer.new()
var _leave_channel_timer = Timer.new()

func _ready() -> void:
	_join_channel_timer.wait_time = 5
	_join_channel_timer.one_shot = true
	_join_channel_timer.timeout.connect(on_join_channels)
	
	_leave_channel_timer.wait_time = 15
	_leave_channel_timer.one_shot = true
	_leave_channel_timer.timeout.connect(on_leave_channel)
	
	add_child(_join_channel_timer)
	add_child(_leave_channel_timer)
	
	_join_channel_timer.start()
	_leave_channel_timer.start()
	
	HypeRate.connected.connect(on_connect)
	HypeRate.channel_joined.connect(on_channel_joined)
	HypeRate.heartbeat_received.connect(on_heartbeat_received)
	HypeRate.clip_created.connect(on_clip_created)
	HypeRate.channel_left.connect(on_channel_left)
	HypeRate.disconnected.connect(on_disconnect)
	HypeRate.connect_to_server()

func on_connect() -> void:
	print("Connected to HypeRate")

func on_channel_joined(channel_name: String) -> void:
	print("Joined channel: %s" % channel_name)
	
func on_channel_left(channel_name: String) -> void:
	print("Left channel: %s" % channel_name)

func on_heartbeat_received(channel_name: String, heartbeat: int) -> void:
	print("Received new heartbeat %s for ID %s" % [heartbeat, channel_name])

func on_clip_created(channel_name: String, twitch_slug: String) -> void:
	print("ID %s created a new Twitch Clip: https://clips.twitch.tv/%s" % [channel_name, twitch_slug])

func on_disconnect() -> void:
	print("Disconnected from HypeRate")

func on_join_channels() -> void:
	HypeRate.join_heartbeat_channel("internal-testing")

func on_leave_channel() -> void:
	HypeRate.leave_heartbeat_channel("internal-testing")
