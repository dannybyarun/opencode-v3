# opencode-v3.ps1 — bootstrap a portable opencode-v3 instance (Windows).
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   $env:OPENCODE_V3_ROOT = "D:\opencode-v3"; powershell -File .\install.ps1
#
# The Windows build has no usque/WARP tunnel: the v3 relay runs on the
# machine's native egress. It is still a fully separate instance (own HOME,
# own database, own sessions, own project, own relay port, own pins/logs).
$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($env:OPENCODE_V3_ROOT) {
  $Root = $env:OPENCODE_V3_ROOT
} else {
  $Root = Join-Path $env:USERPROFILE ".opencode-v3"
}
$HomeDir = Join-Path $Root "home"
$PluginDir = Join-Path $HomeDir ".config\opencode\plugin"

Write-Host "install: root -> $Root"
foreach ($d in @(
  (Join-Path $PluginDir "resources"),
  (Join-Path $Root "state"),
  (Join-Path $Root "work"),
  (Join-Path $Root "mint"),
  (Join-Path $Root "bin")
)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# --- the relay plugin + resources -------------------------------------------
$plugin = Join-Path $Here "plugin\bun-relay.ts"
if (Test-Path $plugin) {
  Copy-Item $plugin (Join-Path $PluginDir "bun-relay.ts") -Force
  Copy-Item (Join-Path $Here "plugin\resources\*") (Join-Path $PluginDir "resources") -Force
  Write-Host "install: relay plugin installed -> $PluginDir"
} else {
  Write-Host "install: plugin\ not found next to install.ps1 — run it from a clone"
  exit 1
}

# --- the launcher -----------------------------------------------------------
Copy-Item (Join-Path $Here "opencode-v3.cmd") (Join-Path $Root "bin\opencode-v3.cmd") -Force
Write-Host "install: launcher installed -> $Root\bin\opencode-v3.cmd"

# --- opencode itself --------------------------------------------------------
$oc = Get-Command opencode -ErrorAction SilentlyContinue
if ($oc) {
  Write-Host "install: opencode found: $($oc.Source)"
} else {
  Write-Host "install: opencode NOT found — install it first (https://opencode.ai)"
}

Write-Host ""
Write-Host "install: done"
Write-Host ""
Write-Host "  $Root\bin\opencode-v3.cmd            # interactive"
Write-Host "  $Root\bin\opencode-v3.cmd run `"hi`"   # headless"
Write-Host "  $Root\bin\opencode-v3.cmd status     # what is running"
Write-Host ""
Write-Host "  The v3 has its own HOME, database, sessions, project, relay (43914),"
Write-Host "  pins and logs. It cannot affect any opencode you are already running."
