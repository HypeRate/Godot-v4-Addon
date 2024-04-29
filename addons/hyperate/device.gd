class_name HypeRateDevice
## An utility class for working with device IDs / session IDs

const valid_id_characters = [
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
	]

## Checks if the given input is a valid device ID / session ID.
static func is_valid_device_id(input: String) -> bool:
	if input.to_lower() == "internal-testing":
		return true

	if _has_valid_length(input) == false:
		return false

	if _has_valid_device_id_characters(input) == false:
		return false

	return true

## Tries to extract the device ID based on the given [param input]. [br]
## It returns [code]null[/code] when the ID could not be extracted. [br]
## Otherwise the extracted ID will be returned as String. [br]
## Currently it is only working for the following input: [br]
## - https://app.hyperate.io/my-id [br]
## - https://app.hyperate.io/my-id?some=query&params=here [br]
## - http://app.hyperate.io/my-id [br]
## - http://app.hyperate.io/my-id?some=query&params=here [br]
## - app.hyperate.io/my-id [br]
## - my-id
static func extract_device_id(input: String) -> Variant:
	var url_regex = RegEx.new()
	url_regex.compile("((https?:\\/\\/)?app\\.hyperate\\.io\\/)?(?<device_id>[a-zA-Z0-9\\-]+)(\\?.*)?")

	var search_result = url_regex.search(input)

	if search_result:
		return search_result.get_string("device_id")

	return null

static func _has_valid_length(input: String) -> bool:
	var string_length = input

	if string_length < 3:
		return false

	if string_length > 8:
		return false

	return true

## Checks if the given [param input] contains only characters from a-z, A-Z and 0-9
static func _has_valid_device_id_characters(input: String) -> bool:
	for character in input:
		if valid_id_characters.has(character):
			continue

		return false

	return true
