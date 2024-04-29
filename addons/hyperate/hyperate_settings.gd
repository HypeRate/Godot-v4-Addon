extends Resource

class_name HypeRateSettings

@export
var endpoint_url: String = "wss://app.hyperate.io/socket/websocket"

@export
var api_token: String

@export_range(5, 30)
var heartbeat_interval: int = 10
