# The official HypeRate Godot v4 addon

You can find a rendered version here: https://github.com/HypeRate/Godot-v4-Addon/blob/master/addons/hyperate/README.md

Important note: All functions which are starting with an underscore (`_`) should be considered to be private. They are not part of the public API.

## Usage

1. Install the addon via the AssetLib in Godot
2. Create a new resource inside the project directory called `hyperate.tres` of type `HypeRateSettings`
    - (Optional) Request an API token [here](https://www.hyperate.io/api) if not already done
    - Enter your API token in the inspector
3. (Optional) Connect the HypeRate signals you need to your code
    - HypeRate.connected
    - HypeRate.channel_joined
    - HypeRate.heartbeat_received
    - HypeRate.clip_created
    - HypeRate.channel_left
    - HypeRate.disconnected
4. Call `HypeRate.connect_to_server` in order to establish a connection
5. (Optional) Call `HypeRate.join_heartbeat_channel` or `HypeRate.join_clips_channel` in order to receive events from the user with the given ID
6. (Optional) Call `HypeRate.leave_heartbeat_channel` or `HypeRate.leave_clips_channel` when you don't want to receive any further event from the user with the given ID.
7. Call `HypeRate.disconnect_from_server` when you completely disconnect from the server

NOTE: In order to save valuable resources you should not connect to the servers when the user has not entered their device ID / session ID.

### Extra information

#### Examples

The addon contains an `examples` directory which itself contains a file named `signals.gd`.

It contains an exhaustive example on how you would connect the signals of the `HypeRate` global variable to your own application.

#### Using a different path for the settings file

If you want to put the HypeRateSettings resource in a different directory other the root project directory, you need to change this line and put the new path in it:

```gdscript
# Before
var _hyperate_settings: HypeRateSettings = load("res://hyperate.tres")

# After
var _hyperate_settings: HypeRateSettings = load("res://my/sub/directory/hyperate.tres")
```

## Getting the device ID / session ID

Please read our [online documentation](https://github.com/HypeRate/DevDocs/blob/main/Device%20ID.md).

We highly recommend to use the `HypeRateDevice` class which contains utility functions for extracting the device ID / session ID aswell as checking if the entered ID is correct.

## Changelog

### 2.0.0

#### Important notes

-   The `HypeRate._channels` variable should not be used anymore

#### Breaking changes

-   Renamed the `socket_connected` signal to `connected`
-   Renamed the `socket_disconnected` signal to `disconnected`

#### Other changes

-   Added the `HypeRateDevice` utility class
-   Added the internal `HypeRateNetwork` utility class which contains all Phoenix related packets
-   Added the `clip_created` signal
-   Moved the `examples` directory into the `hyperate` directory
-   Refactored the JSON messages to their own module (HypeRateNetwork)
-   Heavily refactored the public API
    -   Added the following functions
        -   `join_clips_channel/1`
        -   `leave_clips_channel/1`
        -   `join_heartbeat_channel/1`
        -   `leave_heartbeat_channel/1`
        -   `get_channel_type/1`

#### Internal changes

-   Refactored the `HypeRateChannels` module
    -   When joining or leaving a channel we use a real `ref` for network requests

### 1.0.0

Initial release
