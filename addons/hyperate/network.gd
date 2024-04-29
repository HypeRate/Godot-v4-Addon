class_name HypeRateNetwork
## An internal utility class which contains all required packets for Phoenix.

## Returns the JSON representation of the "keep alive" packet
static func keep_alive_packet() -> String:
    return JSON.stringify({
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": 0
	})

## Returns the JSON representation of the "join channel" packet
static func join_channel_packet(topic: String, ref: int) -> String:
    return JSON.stringify({
        "topic": topic,
        "event": "phx_join",
        "payload": {},
        "ref": ref
        })

## Returns the JSON representation of the "leave channel" packet
static func leave_channel_packet(topic: String, ref: int) -> String:
    return JSON.stringify({
        "topic": topic,
        "event": "phx_leave",
        "payload": {},
        "ref": ref
        })
