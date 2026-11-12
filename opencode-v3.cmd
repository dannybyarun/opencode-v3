@echo off
REM opencode-v3.cmd - launch a COMPLETELY SEPARATE opencode instance (Windows).
REM
REM Same idea as the POSIX launcher: its own HOME (USERPROFILE for Bun on
REM Windows), its own project dir, its own relay on 43914, its own pins, mint
REM dir and logs. Nothing it does can touch an opencode you are already
REM running.
REM
REM   opencode-v3.cmd              interactive TUI
REM   opencode-v3.cmd run "hello"  headless, one prompt
REM   opencode-v3.cmd status       what is running
REM   opencode-v3.cmd shell        a shell with the v3 environment
REM Delayed expansion stays OFF on purpose: it would eat "!" characters that
REM belong to the prompt passed to "opencode-v3 run ...".
setlocal DisableDelayedExpansion

if "%OPENCODE_V3_ROOT%"=="" (
  set "ROOT=%USERPROFILE%\.opencode-v3"
) else (
  set "ROOT=%OPENCODE_V3_ROOT%"
)
set "HOME_DIR=%ROOT%\home"
set "STATE=%ROOT%\state"
set "WORK=%ROOT%\work"
set "PLUGIN_DIR=%HOME_DIR%\.config\opencode\plugin"
if "%OPENCODE_V3_RELAY_PORT%"=="" set "RELAY_PORT=43914"
REM The installer pins the exact opencode binary it found (or downloaded) so
REM the v3 always starts the same one, whatever shell launched it. The pin is
REM only used when it points at a file that really exists, so a POSIX path
REM written by the Linux installer can never break this launcher.
if exist "%STATE%\opencode-bin.txt" (
  for /f "usebackq delims=" %%B in ("%STATE%\opencode-bin.txt") do if exist "%%B" set "OPENCODE_BIN=%%B"
)
if "%OPENCODE_BIN%"=="" set "OPENCODE_BIN=opencode"

if not exist "%PLUGIN_DIR%\resources" mkdir "%PLUGIN_DIR%\resources"
if not exist "%STATE%" mkdir "%STATE%"
if not exist "%WORK%" mkdir "%WORK%"
if not exist "%ROOT%\mint" mkdir "%ROOT%\mint"

REM --- environment for the child only ---------------------------------------
set "HOME=%HOME_DIR%"
set "USERPROFILE=%HOME_DIR%"
set "OPENCODE_RELAY_PORT=%RELAY_PORT%"
set "OPENCODE_RELAY_DIR=%PLUGIN_DIR%"
set "OPENCODE_RELAY_MINT_DIR=%ROOT%\mint"
set "OPENCODE_RELAY_ACTIVITY_LOG=%STATE%\relay-activity.log"
set "OPENCODE_RELAY_UPSTREAM_FILE=%STATE%\relay-upstream.txt"
set "OPENCODE_RELAY_DIRECT_EGRESS_FLAG=%STATE%\direct-egress"
set "OPENCODE_RELAY_RESCUE_LOG=%STATE%\rescue.log"
set "OPENCODE_ROTATE_MARKER=%STATE%\.rotate.inprogress"
REM No usque on Windows: the v3 relay uses the device's native egress and has
REM no proxy of its own, so it never shares a bucket with another opencode.
set "HTTPS_PROXY="
set "HTTP_PROXY="
set "OPENCODE_RELAY_PROXY="
set "NO_PROXY=127.0.0.1,localhost,::1"
set "no_proxy=127.0.0.1,localhost,::1"

REM --- point the v3 opencode at the v3 relay --------------------------------
if /i not "%~1"=="direct" (
  >"%HOME_DIR%\.config\opencode\opencode.json" echo {"$schema":"https://opencode.ai/config.json","provider":{"opencode":{"options":{"baseURL":"http://127.0.0.1:%RELAY_PORT%/openai/v1"}}}}
) else (
  if exist "%HOME_DIR%\.config\opencode\opencode.json" del /q "%HOME_DIR%\.config\opencode\opencode.json"
)

if /i "%~1"=="status" (
  echo root       : %ROOT%
  echo v3 relay   : http://127.0.0.1:%RELAY_PORT%/relay-health
  echo v3 db      : %HOME_DIR%\.local\share\opencode\opencode.db
  echo v3 project : %WORK%
  echo v3 opencode: %OPENCODE_BIN%
  echo tunnel     : none on Windows ^(native egress^)
  exit /b 0
)

cd /d "%WORK%"
if /i "%~1"=="run" goto :do_run
if /i "%~1"=="shell" (
  cmd /k
  exit /b 0
)
"%OPENCODE_BIN%" --standalone %*
exit /b %errorlevel%

REM --- run: rebuild the argument list by hand --------------------------------
REM "%*" is NOT affected by SHIFT in a batch file, so passing it after a
REM SHIFT would smuggle the literal word "run" into the prompt. Read %1..%9
REM one at a time, each on its own line so every SHIFT is seen immediately.
REM Each argument is re-quoted so spacing and inner quotes survive intact.
:do_run
shift
set "ARGS="
:do_run_next
if "%~1"=="" goto :do_run_exec
set "ARGS=%ARGS% "%~1""
shift
goto :do_run_next
:do_run_exec
"%OPENCODE_BIN%" run --standalone%ARGS%
exit /b %errorlevel%
