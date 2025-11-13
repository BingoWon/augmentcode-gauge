extends Control

## Augment Code Credits Gauge - Desktop Widget
## Displays API usage credits in a transparent floating window

# API Configuration
const API_URL := "https://app.augmentcode.com/api/credits"
const REFRESH_INTERVAL := 60.0
const CONFIG_PATH := "user://config.ini"

# Visual Constants
const COLOR_BG_NORMAL := Color(0.1, 0.12, 0.15, 0.15)
const COLOR_BG_ERROR := Color(0.8, 0.1, 0.1, 0.3)
const COLOR_BORDER_NORMAL := Color(0.2, 0.6, 1, 0.2)
const COLOR_BORDER_ERROR := Color(1, 0.2, 0.2, 0.6)
const COLOR_PROGRESS_BG := Color(0.2, 0.2, 0.25, 0.8)
const COLOR_GREEN := Color(0.2, 1, 0.4, 1)
const COLOR_YELLOW := Color(1, 0.8, 0.2, 1)
const COLOR_RED := Color(1, 0.3, 0.3, 1)

# Thresholds
const THRESHOLD_HIGH := 0.5
const THRESHOLD_LOW := 0.25

# UI References
@onready var http_request := $HTTPRequest
@onready var timer := $Timer
@onready var panel := $Panel
@onready var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
@onready var progress_bar := $Panel/Content/ProgressBar
@onready var progress_bg := progress_bar.get_theme_stylebox("background") as StyleBoxFlat
@onready var progress_fill := progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
@onready var percent_label := $Panel/Content/PercentLabel
@onready var ratio_label := $Panel/Content/RatioLabel

# State
var _dragging := false
var _drag_start_pos := Vector2.ZERO
var _session_cookie := ""
var _proxy_cookie := ""

func _ready() -> void:
	_load_config()
	_load_cookies()
	_load_window_position()
	_setup_ui()
	timer.wait_time = REFRESH_INTERVAL
	http_request.request_completed.connect(_on_request_completed)
	fetch_credits()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_window_position()
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			# 记录鼠标相对于窗口左上角的偏移
			var mouse_pos := DisplayServer.mouse_get_position()
			var win_pos := get_window().position
			_drag_start_pos = Vector2(mouse_pos.x - win_pos.x, mouse_pos.y - win_pos.y)
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		# 窗口位置 = 全局鼠标位置 - 偏移
		var mouse_pos := DisplayServer.mouse_get_position()
		get_window().position = Vector2i(mouse_pos.x - int(_drag_start_pos.x), mouse_pos.y - int(_drag_start_pos.y))


func _on_timer_timeout() -> void:
	fetch_credits()


func fetch_credits() -> void:
	if _session_cookie.is_empty() or _proxy_cookie.is_empty():
		return

	var headers := PackedStringArray([
		"Cookie: _session=%s; web_rpc_proxy_session=%s" % [_session_cookie, _proxy_cookie],
		"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
	])

	http_request.request(API_URL, headers)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	match response_code:
		200:
			_handle_success(body)
		401:
			_show_error("Cookie expired")
		_:
			_show_error("Error: %d" % response_code)


func _handle_success(body: PackedByteArray) -> void:
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_show_error("Parse error")
		return

	var data := json.data as Dictionary
	if data.is_empty():
		return

	_update_ui(data)
	_set_normal_style()

func _update_ui(data: Dictionary) -> void:
	var remaining := data.get("usageUnitsRemaining", 0) as int
	var used := data.get("usageUnitsUsedThisBillingCycle", 0) as int
	var total := remaining + used

	if total == 0:
		_clear_ui()
		return

	var percent := float(remaining) / float(total)
	var color := _get_color_for_percent(percent)

	percent_label.text = "%.1f%%" % (percent * 100)
	percent_label.modulate = color

	ratio_label.text = "%s / %s" % [_format_number(remaining), _format_number(total)]

	progress_bar.value = percent
	progress_fill.bg_color = color


func _clear_ui() -> void:
	percent_label.text = ""
	ratio_label.text = ""
	progress_bar.value = 0.0


func _show_error(message: String) -> void:
	panel_style.bg_color = COLOR_BG_ERROR
	panel_style.border_color = COLOR_BORDER_ERROR

	percent_label.text = "ERROR"
	percent_label.modulate = COLOR_RED
	ratio_label.text = message
	progress_bar.value = 0.0
	progress_fill.bg_color = COLOR_RED


func _set_normal_style() -> void:
	panel_style.bg_color = COLOR_BG_NORMAL
	panel_style.border_color = COLOR_BORDER_NORMAL


func _get_color_for_percent(percent: float) -> Color:
	if percent > THRESHOLD_HIGH:
		return COLOR_GREEN
	elif percent > THRESHOLD_LOW:
		return COLOR_YELLOW
	else:
		return COLOR_RED


func _format_number(num: int) -> String:
	var text := str(num)
	var result := ""

	for i in range(text.length()):
		if i > 0 and (text.length() - i) % 3 == 0:
			result += ","
		result += text[i]

	return result


func _setup_ui() -> void:
	# 设置进度条背景色
	progress_bg.bg_color = COLOR_PROGRESS_BG


func _load_cookies() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_show_error("No config file")
		return

	_session_cookie = config.get_value("cookies", "session", "")
	_proxy_cookie = config.get_value("cookies", "proxy", "")

	if _session_cookie.is_empty() or _proxy_cookie.is_empty():
		_show_error("Invalid cookies")

func _load_window_position() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	var x: int = config.get_value("window", "position_x", -1)
	var y: int = config.get_value("window", "position_y", -1)

	if x >= 0 and y >= 0:
		get_window().position = Vector2i(x, y)

func _save_window_position() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	var pos := get_window().position
	config.set_value("window", "position_x", pos.x)
	config.set_value("window", "position_y", pos.y)

	config.save(CONFIG_PATH)


func _load_config() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err == OK:
		return

	if err == ERR_FILE_NOT_FOUND:
		# 只在文件不存在时创建
		config.set_value("cookies", "session", "")
		config.set_value("cookies", "proxy", "")
		config.save(CONFIG_PATH)

		push_warning("Config file created at: %s" % CONFIG_PATH)
		push_warning("Please edit the config file and add your cookies.")

