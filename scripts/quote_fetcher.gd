extends Node

signal quote_received(text: String)

const QUOTE_URL := "https://api.adviceslip.com/advice"
const FETCH_INTERVAL := 20.0
const INITIAL_DELAY := 10.0

@onready var http_request: HTTPRequest = HTTPRequest.new()
@onready var timer: Timer = Timer.new()

func _ready() -> void:
	add_child(http_request)
	add_child(timer)
	http_request.request_completed.connect(_on_request_completed)
	timer.wait_time = FETCH_INTERVAL
	timer.timeout.connect(fetch)
	await get_tree().create_timer(INITIAL_DELAY).timeout
	fetch()
	timer.start()

func fetch() -> void:
	var url := QUOTE_URL + "?t=" + str(Time.get_ticks_msec())
	http_request.request(url)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("slip") and json["slip"].has("advice"):
		quote_received.emit(json["slip"]["advice"])
