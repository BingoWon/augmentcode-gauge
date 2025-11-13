# Augmentcode Gauge

Minimalist desktop floating window for real-time monitoring of Augment Code API usage credits.

## Features

- 🎮 **Borderless Design** - Transparent floating window, always on top
- 📊 **Real-time Monitoring** - Auto-refresh every 60 seconds
- 🎨 **Smart Colors** - Auto color-coding based on remaining credits (green/yellow/red)
- 🖱️ **Draggable** - Click and drag anywhere on the window
- 💾 **Position Memory** - Remembers window position between sessions
- 🔒 **Secure Config** - Cookies stored in external config file

## Display

```
88.3%            ← Remaining percentage (1 decimal)
████████░░       ← Progress bar
666,141 / 754,900 ← Remaining / Total
```

## Quick Start

### 1. Configure Cookies

Create config file manually:

```bash
mkdir -p ~/Library/Application\ Support/Godot/app_userdata/Augmentcode\ gauge/
nano ~/Library/Application\ Support/Godot/app_userdata/Augmentcode\ gauge/config.ini
```

Add your cookies:

```ini
[cookies]
session = "your_session_cookie_value"
proxy = "your_web_rpc_proxy_session_value"
```

**How to get cookies:**

1. Open Edge browser, visit https://app.augmentcode.com
2. Press F12 to open DevTools
3. Go to Application → Cookies → app.augmentcode.com
4. Copy values of `_session` and `web_rpc_proxy_session`

### 2. Run Application

```bash
./run.sh
```

## Technical Details

### Code Quality

- ✅ All magic numbers extracted as constants
- ✅ Full type annotations (GDScript 2.0)
- ✅ Single responsibility function design
- ✅ Pattern matching for HTTP status codes

### Security

- ✅ Cookies moved from source code to external config file
- ✅ Config path: `~/Library/Application Support/Godot/app_userdata/Augmentcode gauge/config.ini`

### UI Optimizations

- ✅ Removed redundant Spacer nodes
- ✅ Direct StyleBoxFlat modification (no modulate)
- ✅ Fixed dragging offset calculation bug
- ✅ Optimized transparency (background 15%, border 20%)
- ✅ Progress bar background opacity increased to 0.8 for better visibility

### Performance

- ✅ Cookies loaded once at startup (not every 60 seconds)
- ✅ Cached session and proxy cookies in memory
- ✅ Reduced file I/O operations

### File Structure

```
.
├── main.gd           # Core logic (211 lines, modern GDScript)
├── main.tscn         # UI scene (optimized node structure)
├── project.godot     # Project configuration
├── run.sh            # Launch script (with error checking)
└── README.md         # This file
```

### Constants

```gdscript
# API Configuration
const API_URL := "https://app.augmentcode.com/api/credits"
const REFRESH_INTERVAL := 60.0
const CONFIG_PATH := "user://config.ini"

# Color Theme
const COLOR_BG_NORMAL := Color(0.1, 0.12, 0.15, 0.15)
const COLOR_BG_ERROR := Color(0.8, 0.1, 0.1, 0.3)
const COLOR_GREEN := Color(0.2, 1, 0.4, 1)
const COLOR_YELLOW := Color(1, 0.8, 0.2, 1)
const COLOR_RED := Color(1, 0.3, 0.3, 1)
const COLOR_PROGRESS_BG := Color(0.2, 0.2, 0.25, 0.8)

# Thresholds
const THRESHOLD_HIGH := 0.5   # >50% shows green
const THRESHOLD_LOW := 0.25   # <25% shows red
```

## Troubleshooting

### Cookie Expired

When the interface turns red showing "Cookie expired", edit the config file and update your cookies:

```bash
nano ~/Library/Application\ Support/Godot/app_userdata/Augmentcode\ gauge/config.ini
```

### Config File Format

Ensure the config file format is correct (note the quotes):

```ini
[cookies]
session = "your_session_cookie_value"
proxy = "your_web_rpc_proxy_session_value"
```

### Application Won't Start

Check if Godot is installed at the default path:

```bash
/Applications/Godot.app/Contents/MacOS/Godot
```

If the path is different, modify the `GODOT_BIN` variable in `run.sh`.

## System Requirements

- macOS (tested on M4 Pro)
- Godot 4.5.1+
- Edge browser (for obtaining cookies)

## Development

Open the project in Godot editor:

```bash
open -a Godot project.godot
```

## License

MIT

