#!/usr/bin/env bash
# install.sh — bootstrap a portable opencode-v3 instance.
#
#   bash install.sh                 # default root: ~/.opencode-v3
#   OPENCODE_V3_ROOT=/path bash install.sh
#
# Works on Linux, macOS, WSL and Git Bash. The optional WARP tunnel (usque)
# is only used where the binary exists; everywhere else the v3 relay runs on
# the device's native egress.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${OPENCODE_V3_ROOT:-$HOME/.opencode-v3}
HOME_DIR="$ROOT/home"
PLUGIN_DIR="$HOME_DIR/.config/opencode/plugin"

say() { printf 'install: %s\n' "$*"; }

say "root -> $ROOT"
mkdir -p "$PLUGIN_DIR/resources" "$ROOT/state" "$ROOT/work" "$ROOT/mint" \
  "$ROOT/bin" "$ROOT/tunnel" || {
  say "could not create the layout"
  exit 1
}

# --- the relay plugin + resources -------------------------------------------
if [ -f "$HERE/plugin/bun-relay.ts" ]; then
  cp "$HERE/plugin/bun-relay.ts" "$PLUGIN_DIR/"
  cp "$HERE"/plugin/resources/* "$PLUGIN_DIR/resources/" 2>/dev/null || true
  say "relay plugin installed -> $PLUGIN_DIR"
else
  say "plugin/ not found next to install.sh — are you running it from a clone?"
  exit 1
fi

# --- the tunnel plumbing (Linux-ish only) ----------------------------------
for f in warp-rotate.sh tunnel-watchdog.sh; do
  if [ -f "$HERE/bin/$f" ]; then
    cp "$HERE/bin/$f" "$ROOT/bin/"
    chmod +x "$ROOT/bin/$f" 2>/dev/null || true
  fi
done
say "tunnel helpers installed -> $ROOT/bin (used only if usque exists)"

# --- the launcher -----------------------------------------------------------
cp "$HERE/opencode-v3" "$ROOT/bin/opencode-v3"
chmod +x "$ROOT/bin/opencode-v3" 2>/dev/null || true
ln -sf "$ROOT/bin/opencode-v3" "$HOME/.local/bin/opencode-v3" 2>/dev/null || true
say "launcher installed -> $ROOT/bin/opencode-v3"

# --- opencode itself --------------------------------------------------------
if command -v opencode >/dev/null 2>&1; then
  say "opencode found: $(command -v opencode)"
else
  say "opencode NOT found — install it first (https://opencode.ai) or set OPENCODE_BIN"
fi

# --- the optional tunnel ----------------------------------------------------
if command -v usque >/dev/null 2>&1; then
  say "usque found: $(command -v usque) — the v3 will use its own WARP tunnel"
else
  say "no usque — the v3 relay will use this device's native egress (fine:"
  say "  it is still a fully separate instance; it just has no rotatable"
  say "  second bucket)"
fi

cat <<EOF

$(say "done")

  $ROOT/bin/opencode-v3            # interactive
  $ROOT/bin/opencode-v3 run "hi"   # headless
  $ROOT/bin/opencode-v3 status     # what is running

  The v3 has its own HOME, database, sessions, project, relay (43914), pins
  and logs. It cannot affect any opencode you are already running.
EOF
