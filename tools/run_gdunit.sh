#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
TEST_PATH="${1:-res://test/gdunit}"

"$GODOT_BIN" \
  --headless \
  --path "$ROOT" \
  -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a "$TEST_PATH" \
  --ignoreHeadlessMode
