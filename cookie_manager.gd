extends Node

# Cookie管理器 - 自动从浏览器读取Cookie

const COOKIE_PATHS = {
	"chrome": "~/Library/Application Support/Google/Chrome/Default/Cookies",
	"edge": "~/Library/Application Support/Microsoft Edge/Default/Cookies",
	"safari": "~/Library/Cookies/Cookies.binarycookies",
	"firefox": "~/Library/Application Support/Firefox/Profiles/"
}

const DOMAIN = "app.augmentcode.com"

# 从配置文件读取Cookie
func load_cookies_from_config() -> Dictionary:
	var config_path = "user://cookies.cfg"
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		var session = config.get_value("cookies", "session", "")
		var proxy = config.get_value("cookies", "proxy", "")
		
		if session != "" and proxy != "":
			print("✓ Loaded cookies from config file")
			return {
				"session": session,
				"proxy": proxy
			}
	
	return {}

# 保存Cookie到配置文件
func save_cookies_to_config(session: String, proxy: String):
	var config_path = "user://cookies.cfg"
	var config = ConfigFile.new()
	
	config.set_value("cookies", "session", session)
	config.set_value("cookies", "proxy", proxy)
	config.set_value("cookies", "last_updated", Time.get_datetime_string_from_system())
	
	config.save(config_path)
	print("✓ Saved cookies to config file")

# 从剪贴板读取Cookie（用户从浏览器复制）
func load_cookies_from_clipboard() -> Dictionary:
	var clipboard = DisplayServer.clipboard_get()
	
	# 尝试解析剪贴板中的Cookie
	var session = ""
	var proxy = ""
	
	# 查找 _session=
	var session_start = clipboard.find("_session=")
	if session_start != -1:
		var session_end = clipboard.find(";", session_start)
		if session_end == -1:
			session_end = clipboard.length()
		session = clipboard.substr(session_start, session_end - session_start)
		session = session.replace("_session=", "").strip_edges()
	
	# 查找 web_rpc_proxy_session=
	var proxy_start = clipboard.find("web_rpc_proxy_session=")
	if proxy_start != -1:
		var proxy_end = clipboard.find(";", proxy_start)
		if proxy_end == -1:
			proxy_end = clipboard.length()
		proxy = clipboard.substr(proxy_start, proxy_end - proxy_start)
		proxy = proxy.replace("web_rpc_proxy_session=", "").strip_edges()
	
	if session != "" and proxy != "":
		print("✓ Loaded cookies from clipboard")
		save_cookies_to_config(session, proxy)
		return {
			"session": session,
			"proxy": proxy
		}
	
	return {}

# 获取Cookie（优先级：配置文件 > 剪贴板 > 硬编码）
func get_cookies() -> Dictionary:
	# 1. 尝试从配置文件读取
	var cookies = load_cookies_from_config()
	if not cookies.is_empty():
		return cookies
	
	# 2. 尝试从剪贴板读取
	cookies = load_cookies_from_clipboard()
	if not cookies.is_empty():
		return cookies
	
	# 3. 返回空（需要用户提供）
	print("⚠ No cookies found. Please copy cookies from browser.")
	return {}

# 格式化Cookie为HTTP Header
func format_cookie_header(cookies: Dictionary) -> String:
	if cookies.is_empty():
		return ""
	
	return "_session=" + cookies.get("session", "") + "; web_rpc_proxy_session=" + cookies.get("proxy", "")

# 检查Cookie是否有效（通过测试请求）
func validate_cookies(cookies: Dictionary, callback: Callable):
	if cookies.is_empty():
		callback.call(false)
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result, response_code, headers, body):
		http.queue_free()
		callback.call(response_code == 200)
	)
	
	var cookie_header = format_cookie_header(cookies)
	var headers = [
		"Cookie: " + cookie_header,
		"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
	]
	
	http.request("https://app.augmentcode.com/api/credits", headers)

