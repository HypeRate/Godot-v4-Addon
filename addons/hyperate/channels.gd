class_name HypeRateChannels

var joining_channels: Dictionary = {}
var joined_channels: Array[String] = []
var leaving_channels: Dictionary = {}

## This array contains all currently used refs / request IDs.
var refs_in_use: Array[int] = []

## The random number generator for generating new refs.
var rng = RandomNumberGenerator.new()

enum RefType {
	Unknown,
	Join,
	Leave
}

enum ChannelType {
	Unknown,
	Heartbeat,
	Clips
}

## Returns the RefType for the given ref
func get_reftype_by_ref(ref: int) -> RefType:
	if joining_channels.find_key(ref) != null:
		return RefType.Join

	if leaving_channels.find_key(ref) != null:
		return RefType.Leave

	return RefType.Unknown

## Generates a new random "ref" aka request id
func _generate_random_ref() -> int:
	var random_number = rng.randi()

	while refs_in_use.has(random_number):
		random_number = rng.randi()

	return random_number

## This functions adds the given channel name to the list of [code]joining_channels[/code] and returns the generated ref. [br]
## When the channel is about to be joined it returns -1. [br]
## When the channel has already been joined it returns -1. [br]
## When the channel is about to leave, then it will be removed from the [code]leaving_channels[/code] dictionary.
func add_channel_to_join(channel_name: String) -> int:
	if joining_channels.has(channel_name):
		return (-1)

	if joined_channels.has(channel_name):
		return (-1)

	if leaving_channels.has(channel_name):
		# Remove the current ref for the leaving channel
		var leaving_channel_ref = leaving_channels[channel_name]
		refs_in_use.erase(leaving_channel_ref)
		leaving_channels.erase(channel_name)

	var join_ref = _generate_random_ref()

	refs_in_use.append(join_ref)
	joining_channels[channel_name] = join_ref

	return join_ref

## This function adds the given channel name to the list of [code]leaving_channels[/code] and returns the generated ref. [br]
## When the channel is about to be joined it returns -1 and removes the channel from the [code]joining_channels[/code] dictionary. [br]
## When the channel was never joined it also returns -1.
func leave_channel(channel_name: String) -> int:
	if joined_channels.has(channel_name) == false:
		return (-1)

	if joining_channels.has(channel_name):
		# Remove the current ref for the joining channel
		var joining_channel_ref = joining_channels[channel_name]
		refs_in_use.erase(joining_channel_ref)
		joining_channels.erase(channel_name)

	var leave_ref = _generate_random_ref()

	joined_channels.erase(channel_name)
	leaving_channels[channel_name] = leave_ref
	refs_in_use.append(leave_ref)

	return leave_ref

## Returns a string array of channels which should be joined after a connection loss.
func get_channels_to_join() -> Array[String]:
	var channels_to_leave = leaving_channels.keys()
	var result: Array[String] = []

	var channels_to_join = joined_channels
	channels_to_join.append_array(joining_channels.keys())

	for channel_to_join in channels_to_join:
		if channels_to_leave.has(channel_to_join):
			continue

		result.append(channel_to_join)

	return result

## This function gets called when the packet processor determined that the given ref belongs to a channel which was joined on the server.
func handle_join(ref: int) -> void:
	var joined_channel_name = joining_channels.find_key(ref)

	if joined_channel_name == null:
		return

	refs_in_use.erase(ref)
	joining_channels.erase(joined_channel_name)
	joined_channels.append(joined_channel_name)

## This function gets called when the packet processor determined that the given ref belongs to a channel which should be left.
func handle_leave(ref: int) -> void:
	var left_channel_name = leaving_channels.find_key(ref)

	if left_channel_name == null:
		return

	refs_in_use.erase(ref)
	leaving_channels.erase(left_channel_name)

## Empties the channels to join, channels to leave and all refs which are currently used.
func handle_reconnect() -> void:
	joining_channels.clear()
	leaving_channels.clear()
	refs_in_use.clear()
