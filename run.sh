#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

if [ ! -f "$GODOT_BIN" ]; then
    echo "Error: Godot not found at $GODOT_BIN"
    exit 1
fi

exec "$GODOT_BIN" --main-scene res://main.tscn
