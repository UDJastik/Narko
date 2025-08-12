extends Node

class_name OverpassClient

@export var overpass_endpoint: String = "https://overpass-api.de/api/interpreter"
@export var max_retries: int = 3
@export var retry_backoff_sec: float = 1.5
@export var throttle_interval_sec: float = 0.5

var _last_request_time: float = -1.0
var _http: HTTPRequest

signal response_success(json: Dictionary)
signal response_error(message: String, code: int)

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func query_async(overpass_q: String) -> void:
	# Non-blocking request.
	await _throttle()
	var body := "data=" + overpass_q.uri_encode()
	var err := _http.request(overpass_endpoint, ["Content-Type: application/x-www-form-urlencoded"], HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("response_error", "HTTPRequest error: %s" % [err], err)

func query_with_retries(overpass_q: String) -> Dictionary:
	# Synchronous-style helper via await; returns {} on failure.
	var attempt := 0
	while attempt <= max_retries:
		await _throttle()
		var body := "data=" + overpass_q.uri_encode()
		var err := _http.request(overpass_endpoint, ["Content-Type: application/x-www-form-urlencoded"], HTTPClient.METHOD_POST, body)
		if err != OK:
			attempt += 1
			await get_tree().create_timer(retry_backoff_sec * attempt).timeout
			continue
			
		var result := await _wait_for_result()
		if result.has("ok") and result["ok"]:
			return result.get("data", {})
		attempt += 1
		await get_tree().create_timer(retry_backoff_sec * attempt).timeout
	return {}

func _wait_for_result() -> Dictionary:
	var done := false
	var output := {}
	var on_ok = func(json: Dictionary):
		done = true
		output = {"ok": true, "data": json}
	var on_err = func(message: String, code: int):
		done = true
		output = {"ok": false, "message": message, "code": code}
	response_success.connect(on_ok)
	response_error.connect(on_err)
	while not done:
		await get_tree().process_frame
	response_success.disconnect(on_ok)
	response_error.disconnect(on_err)
	return output

func _throttle() -> void:
	var now := Time.get_unix_time_from_system()
	if _last_request_time < 0.0:
		_last_request_time = now
		return
	var elapsed := now - _last_request_time
	if elapsed < throttle_interval_sec:
		await get_tree().create_timer(throttle_interval_sec - elapsed).timeout
	_last_request_time = Time.get_unix_time_from_system()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("response_error", "Network error", result)
		return
	if response_code < 200 or response_code >= 300:
		emit_signal("response_error", "HTTP code %s" % [response_code], response_code)
		return
	var text := body.get_string_from_utf8()
	var json := JSON.parse_string(text)
	if typeof(json) != TYPE_DICTIONARY:
		emit_signal("response_error", "JSON parse error", -1)
		return
	emit_signal("response_success", json)