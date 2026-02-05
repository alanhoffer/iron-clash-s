extends Node

signal health_checked(ok: bool)
signal combat_simulated(replay: Dictionary)
signal request_failed(message: String)

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func check_health(base_url: String) -> void:
	_http.cancel_request()
	var url := base_url.trim_suffix("/") + "/health"
	var err := _http.request(url)
	if err != OK:
		request_failed.emit("HTTPRequest error: %s" % str(err))

func simulate_combat(base_url: String, payload: Dictionary) -> void:
	_http.cancel_request()
	var url := base_url.trim_suffix("/") + "/combat/simulate"
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		request_failed.emit("HTTPRequest error: %s" % str(err))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("Network result=%s" % str(result))
		return

	var text: String = body.get_string_from_utf8()
	var temp: Variant
	temp = JSON.parse_string(text)
	if typeof(temp) != TYPE_DICTIONARY:
		request_failed.emit("Invalid JSON response (code=%s): %s" % [str(response_code), text.left(200)])
		return
	
	var parsed: Dictionary = temp
	
	# Cheap routing by shape.
	if parsed.has("status"):
		health_checked.emit(response_code >= 200 and response_code < 300 and parsed.get("status") == "ok")
		return

	if parsed.has("events") and parsed.has("winner_id"):
		if response_code < 200 or response_code >= 300:
			request_failed.emit("Combat simulate failed (code=%s): %s" % [str(response_code), text.left(200)])
			return
		combat_simulated.emit(parsed)
		return

	request_failed.emit("Unknown response (code=%s): %s" % [str(response_code), text.left(200)])
