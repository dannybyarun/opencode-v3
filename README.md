# opencode-v3 — a second, fully separate opencode instance

Run **another opencode** alongside the one you are already using: its own
database, its own sessions, its own project, its own relay, its own tunnel.
Anything you do in it — rotate the egress, kill the tunnel, drain the quota,
break the plugin — cannot disconnect the opencode you are talking to.

It is also the **resilient** one: the v3's opencode talks to the gateway
through the v3 relay, so it inherits everything the relay knows how to do:

- the gateway whitelist (the relay rewrites the body into the approved
  "agent class" — the free models only accept that shape),
- the free-model **pool rotation** (ten free models, the relay rotates when
  one is drained),
- the **egress ladder** (proxied path first, then the device's native
  egress — a dead proxy no longer kills the request),
- the **spin budget** (a request is never parked for minutes),
- the **rescue chain** (rotate the egress and refresh the credential in the
  background).

## Install

### Linux / macOS / WSL / Git Bash

```bash
git clone https://github.com/dannybyarun/opencode-v3.git
cd opencode-v3
bash install.sh
~/.local/bin/opencode-v3            # interactive
~/.local/bin/opencode-v3 run "hi"   # headless
~/.local/bin/opencode-v3 status     # what is running
```

### Windows (PowerShell)

```powershell
git clone https://github.com/dannybyarun/opencode-v3.git
cd opencode-v3
powershell -ExecutionPolicy Bypass -File .\install.ps1
$env:USERPROFILE\.opencode-v3\bin\opencode-v3.cmd
```

Requires [opencode](https://opencode.ai) to be installed and on `PATH`.

## Platform matrix

| | Linux / macOS / WSL | Windows |
|---|---|---|
| separate HOME, DB, sessions, project | ✅ | ✅ |
| own relay (port 43914) with pool/ladder/budget/rescue | ✅ | ✅ |
| own **rotatable** WARP tunnel (usque) | ✅ (if `usque` is present) | ❌ → native egress |
| egress recovery by rotating the IP | ✅ | native egress only (a second bucket can be added by pointing `OPENCODE_RELAY_PROXY` at any local HTTP proxy) |
| the live opencode is unaffected | ✅ | ✅ |

Where `usque` is not available the v3 relay simply uses the machine's native
egress — still a completely separate instance, it just has no *rotatable*
second bucket. To give it one, point it at any local HTTP proxy:

```bash
OPENCODE_V3_TUNNEL_PORT=8080 OPENCODE_RELAY_PROXY=http://127.0.0.1:8080 opencode-v3
```

## Layout

```
<root>/                     default ~/.opencode-v3   (%USERPROFILE%\.opencode-v3)
  home/                     HOME for the v3 opencode — own DB, config, plugins
  work/                     the v3 project directory (yours to use)
  state/                    logs, reports, pid files, the runtime override files
  mint/                     the v3's scratch dir for identity rotation
  bin/                      the launcher + the tunnel helpers
  tunnel/                   the v3's own WARP registration (where usque exists)
```

Everything is per-instance: the relay port, the proxy, the pins, the mint
directory, the rescue log and the rotator path. Two instances never share a
file.

## Runtime knobs (all optional)

| env | effect |
|---|---|
| `OPENCODE_V3_ROOT` | where the instance lives (default `~/.opencode-v3`) |
| `OPENCODE_V3_RELAY_PORT` | the v3 relay's port (default 43914) |
| `OPENCODE_V3_TUNNEL_PORT` | the v3 tunnel's proxy port (default 40003) |
| `OPENCODE_BIN` | the opencode binary to run (default `opencode`) |
| `OPENCODE_RELAY_SPIN_BUDGET_MS` | how long a request may spin before the relay answers with the last error (default 45000) |
| `OPENCODE_RELAY_AUTOMINT=0` | disable the automatic identity rotation |
| `OPENCODE_RELAY_EGRESS_ROTATE=0` | the rescue chain refreshes the credential but does not touch the egress |

Live-reloadable files (no restart needed):

| file | effect |
|---|---|
| `<root>/state/direct-egress` | the relay bypasses its proxy and uses the native egress |
| `<root>/state/relay-upstream.txt` | point the relay at a different upstream |
| `<root>/state/rescue.log` | the rescue chain's transcript |
| `<root>/state/relay-activity.log` | the relay's activity log |

## What the v3's opencode is allowed to do

Everything the live one can — it is the same binary with a different HOME. It
gets its own sessions, its own history, its own project directory, and it can
be pointed at any OpenAI-compatible endpoint:

```bash
# any client can use the v3 relay
curl http://127.0.0.1:43914/v1/models
OPENAI_BASE_URL=http://127.0.0.1:43914/v1 OPENAI_API_KEY=public my-tool
```

## How it was verified

On an Android device (opencode.mobile + proot), against the live instance:
separate DB and sessions, separate tunnel identity, separate exit IP, a lab
rotation leaving the live tunnel's IP untouched, 40/40 + 21/21 + 14/14
chaos-matrix assertions, and a connection-flap loop where the relay answered
200 in ~2 s right after the tunnel dropped.

The relay itself came from
[`dannybyarun/opencode-freebuff-relay-v2`](https://github.com/dannybyarun/opencode-freebuff-relay-v2),
which documents the gateway findings (whitelist shape, quota unit, model
catalogue) in `VERDICT.md` and `OPENCODE-EXTRACTION.md`.

## License

MIT
