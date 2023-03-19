@tool

class_name hyperate_channels

## Contains all channels which should be joined
var _joining_channels : Array[String] = []

## Contains all channels which where joined
var _joined_channels  : Array[String] = []

## Contains all channels which should be left
var _leaving_channels : Array[String] = []

## Adds the given channel to the list of channels which should be joined
func add_joining_channel(channel_name : String) -> bool:
    if _joined_channels.has(channel_name):
        return false

    if _joining_channels.has(channel_name):
        return false
    
    _joining_channels.append(channel_name)
    return true

## Removes the given channel from the list of channels which should be joined and
## adds it to the list of joined channels
func add_joined_channel(channel_name : String) -> bool:
    if _joined_channels.has(channel_name):
        return false

    if _joining_channels.has(channel_name) == false:
        return false

    _joining_channels.filter(func(joining_channel_name): return joining_channel_name != channel_name)
    _joined_channels.append(channel_name)

    return true

## Leaves the given channel
## Checks if the channel is joined - if not - false is returned
## ATTENTION: It will not check if the given channel_name is in the list of channels to join
func leave_channel(channel_name : String) -> bool:
    if _leaving_channels.has(channel_name) == false:
        return false

    if _joined_channels.has(channel_name) == false:
        return false

    return true

func _to_string() -> String:
    return "Channels { joining: %s, joined: %s, leaving: %s }" % [_joining_channels, _joined_channels, _leaving_channels]

func get_join_channel_packet(channel_name : String):
    return JSON.stringify({
        "topic": ("hr:%s" % channel_name),
        "event": "phx_join",
        "payload": {},
        "ref": 0
        })

func get_leave_channel_packet(channel_name : String):
    return JSON.stringify({
        "topic": ("hr:%s" % channel_name),
        "event": "phx_leave",
        "payload": {},
        "ref": 0
        })
