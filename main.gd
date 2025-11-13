extends Control

# API Configuration
const API_URL = "https://app.augmentcode.com/api/credits"
const SESSION_COOKIE = "_session=eyJvYXV0aDI6c3RhdGUiOiJnMnBpMDduNWNiRmhIMGlFZl8wTi1wcGR6RV9qNGVvTHR5by1TT1A4TWE4Iiwib2F1dGgyOmNvZGVWZXJpZmllciI6Iko3eTFDYTB2Qk9wT0RpRWZIUjluYmYyREphVHM0OWhvQkhxUV9QUjM2T1EiLCJ1c2VyIjp7InVzZXJJZCI6ImZjYWNhYTc0LTAxMTgtNDk2Zi04NDMyLTVhMmI3NGQ3OWRmYyIsInRlbmFudElkIjoiNGRkZDgzYWVlODdiNzZlNGE3M2JmODNlZWQ3MzBmMmYiLCJ0ZW5hbnROYW1lIjoiZDExLWRpc2NvdmVyeTYiLCJzaGFyZE5hbWVzcGFjZSI6ImQxMSIsImVtYWlsIjoiQmluZ293QG91dGxvb2suY29tIiwicm9sZXMiOltdLCJjcmVhdGVkQXQiOjE3NjMwMjk5NTA3NDAsInNlc3Npb25JZCI6ImZhMDY4MmQ5LTA3NzUtNDE5Yy1hOWY3LTI1ZWY3OWMxZjNjMSJ9fQ%3D%3D.0bhyxy2kUb0T5dhdg%2B2GstR%2BskIf%2BOeZFLfP9SKxLH8"
const PROXY_COOKIE = "web_rpc_proxy_session=MTc2MzAzMDc0NnxrNm9MR1paSzVmSUl3dzYxdmRDbFBYWlRTUTFRYU04Q3ZidTFaTFdXai1GNUI3LXpKT0w5dDNqMTd1V1kwUklxZmlFZ1FGS2xhOU5qeDRIQ3Y0dVBMcUZ4dkNQWEJ1b0czY01zeE5GVS1QeTJFbndkeTFUOGU5NUxzRkEwZnppYzVjYV9CLS1MeWVvMzU3SmF3aXR3R1g3eS02WjlHVThsb0VQLUZCaWZwUU9yWnozVU16YXRUc1FVSFpBWmQtUDQ2bjd4TUhzWHcxa0NJZDFTVjVpTVFUR3otNWNxR1lnPXy_QqeKQBXu_AayfuBnD4rUPXvUdjaGO0_K3jkCaksr9Q=="

# UI References
@onready var http_request = $HTTPRequest
@onready var timer = $Timer
@onready var remaining_label = $Panel/VBoxContainer/RemainingLabel
@onready var usage_label = $Panel/VBoxContainer/UsageLabel
@onready var progress_bar = $Panel/VBoxContainer/ProgressBar
@onready var status_label = $Panel/VBoxContainer/StatusLabel

# Data
var usage_data = {}

# Dragging
var dragging = false
var drag_offset = Vector2()

func _ready():
	# Connect HTTP request signal
	http_request.request_completed.connect(_on_request_completed)

	# Make initial request
	fetch_credits()

	print("Augment Gauge started - fetching data every 60 seconds")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_viewport().get_mouse_position()
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		var window = get_window()
		window.position += Vector2i(event.position - drag_offset)

func _on_timer_timeout():
	fetch_credits()

func fetch_credits():
	status_label.text = "Updating..."
	status_label.modulate = Color(0.5, 0.5, 0.5, 1)
	
	var headers = [
		"Cookie: " + SESSION_COOKIE + "; " + PROXY_COOKIE,
		"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		"Accept: */*",
		"Cache-Control: no-cache"
	]
	
	var error = http_request.request(API_URL, headers)
	if error != OK:
		print("HTTP Request error: ", error)
		status_label.text = "Request Failed"
		status_label.modulate = Color(1, 0.3, 0.3, 1)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			usage_data = json.data
			update_ui()
			status_label.text = "✓ Updated " + Time.get_time_string_from_system()
			status_label.modulate = Color(0.2, 1, 0.4, 1)
		else:
			print("JSON Parse Error: ", json.get_error_message())
			status_label.text = "Parse Error"
			status_label.modulate = Color(1, 0.3, 0.3, 1)
	else:
		print("HTTP Response Code: ", response_code)
		status_label.text = "Error: " + str(response_code)
		status_label.modulate = Color(1, 0.3, 0.3, 1)

func update_ui():
	if usage_data.is_empty():
		return
	
	var remaining = usage_data.get("usageUnitsRemaining", 0)
	var used = usage_data.get("usageUnitsUsedThisBillingCycle", 0)
	var available = usage_data.get("usageUnitsAvailable", 0)
	
	# Calculate total (used + remaining)
	var total = used + remaining
	
	# Update remaining label with formatting
	remaining_label.text = format_number(remaining)
	
	# Update usage label
	usage_label.text = "Used: " + format_number(used) + " / " + format_number(total)
	
	# Update progress bar (showing remaining percentage)
	if total > 0:
		var remaining_percent = float(remaining) / float(total)
		progress_bar.value = remaining_percent
		
		# Change color based on remaining percentage
		if remaining_percent > 0.5:
			progress_bar.modulate = Color(0.2, 1, 0.4, 1)  # Green
		elif remaining_percent > 0.25:
			progress_bar.modulate = Color(1, 0.8, 0.2, 1)  # Yellow
		else:
			progress_bar.modulate = Color(1, 0.3, 0.3, 1)  # Red

func format_number(num: int) -> String:
	var str_num = str(num)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count == 3:
			result = "," + result
			count = 0
		result = str_num[i] + result
		count += 1
	
	return result

