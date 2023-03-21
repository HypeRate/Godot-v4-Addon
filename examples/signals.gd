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
	
	HypeRate.socket_connected.connect(on_connect)
	HypeRate.channel_joined.connect(on_channel_joined)
	HypeRate.heartbeat_received.connect(on_heartbeat_received)
	HypeRate.channel_left.connect(on_channel_left)
	HypeRate.socket_disconnected.connect(on_disconnect)
	HypeRate.connect_to_server()

func on_connect():
	print("Connected to HypeRate")

func on_channel_joined(channel_name):
	print("Joined channel: %s" % channel_name)
	
func on_channel_left(channel_name):
	print("Left channel: %s" % channel_name)

func on_heartbeat_received(channel, heartbeat):
	print("Received new heartbeat %s for channel %s" % [heartbeat, channel])

func on_disconnect():
	print("Disconnect from HypeRate")

func on_join_channels():
	HypeRate._channels.add_joining_channel("internal-testing")

func on_leave_channel():
	HypeRate._channels.leave_channel("internal-testing")
