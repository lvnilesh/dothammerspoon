# OpenclawHealth.spoon

A Hammerspoon spoon that monitors the health of your OpenClaw Gateway and displays status in the macOS menu bar.

## Features

- 🟢 **Real-time status indicator** in the menu bar
- **Process monitoring** - detects if the gateway is running
- **HTTP health checks** - verifies the gateway is responding
- **Quick actions** - Start, Stop, Restart gateway from the menu
- **Authenticated Web UI access** - opens the Control UI with your token
- **Log viewer** - quick access to gateway logs

## Status Icons

| Icon | Status | Meaning |
|------|--------|---------|
| 🟢 | Healthy | Gateway running and HTTP responding |
| 🟡 | Warning | Process running but HTTP not responding |
| 🔴 | Error | Gateway not running |
| ⚪ | Unknown | Initial state / checking |

## Installation

### 1. Copy the Spoon

Copy the `OpenclawHealth.spoon` folder to your Hammerspoon Spoons directory:

```bash
cp -r OpenclawHealth.spoon ~/.hammerspoon/Spoons/
```

Or if you're cloning from a repo:

```bash
git clone <repo-url>
cp -r OpenclawHealth.spoon ~/.hammerspoon/Spoons/
```

### 2. Update your init.lua

Add the following to your `~/.hammerspoon/init.lua`:

```lua
-- Load the OpenclawHealth spoon
hs.loadSpoon("OpenclawHealth")

-- Optional: Configure settings (defaults shown)
-- spoon.OpenclawHealth.checkInterval = 30      -- seconds between health checks
-- spoon.OpenclawHealth.gatewayPort = 18789     -- gateway HTTP port
-- spoon.OpenclawHealth.processName = "openclaw-gateway"  -- process to monitor

-- Start monitoring
spoon.OpenclawHealth:start()
```

### 3. Reload Hammerspoon

Either:
- Click the Hammerspoon menu bar icon → **Reload Config**
- Use your reload hotkey (if configured)
- Restart Hammerspoon

## Configuration

All configuration is optional. The defaults work for standard OpenClaw installations.

### Check Interval

How often to poll the gateway health (in seconds):

```lua
spoon.OpenclawHealth.checkInterval = 60  -- check every minute
```

### Gateway Port

If your gateway runs on a non-default port:

```lua
spoon.OpenclawHealth.gatewayPort = 3000
```

### Process Name

If you've renamed or wrapped the gateway process:

```lua
spoon.OpenclawHealth.processName = "my-openclaw"
```

### Config Path

If your OpenClaw config is in a non-standard location:

```lua
spoon.OpenclawHealth.configPath = "/path/to/openclaw.json"
```

### Custom Icons

Change the status icons (defaults shown):

```lua
spoon.OpenclawHealth.icons = {
  healthy = "🟢",
  warning = "🟡",
  error = "🔴",
  unknown = "⚪"
}
```

## Authentication

The spoon automatically reads your gateway auth token from:

1. `~/.openclaw/openclaw.json` → `gateway.auth.token`
2. `OPENCLAW_GATEWAY_TOKEN` environment variable (fallback)

When you click **Open Web UI**, the token is appended as a query parameter for automatic authentication.

> **Note:** Requires `jq` to be installed for reliable JSON parsing. Install with: `brew install jq`

## Menu Actions

| Action | Description |
|--------|-------------|
| **Check Now** | Force an immediate health check |
| **Open Web UI** | Open the Control UI in your browser (with auth) |
| **Start Gateway** | Start the gateway process |
| **Stop Gateway** | Stop the gateway process |
| **Restart Gateway** | Stop and restart the gateway |
| **View Logs** | Open Console.app with the OpenClaw logs directory |

## Example: Full init.lua Integration

```lua
-- Load spoons
hs.loadSpoon("MiroWindowsManager")  -- or your other spoons
hs.loadSpoon("OpenclawHealth")

-- Configure OpenclawHealth
spoon.OpenclawHealth.checkInterval = 30

-- Start OpenclawHealth monitoring
spoon.OpenclawHealth:start()

-- ... rest of your config ...
```

## Stopping the Monitor

To stop the health monitoring (e.g., in a reload function):

```lua
spoon.OpenclawHealth:stop()
```

## Troubleshooting

### Menu bar icon doesn't appear
- Ensure Hammerspoon has accessibility permissions
- Check the Hammerspoon console for errors (Help → Console)

### "Gateway not running" but it is running
- Verify the process name matches: `pgrep -f "openclaw-gateway"`
- Adjust `spoon.OpenclawHealth.processName` if needed

### Web UI opens but shows "unauthorized"
- Ensure `jq` is installed: `brew install jq`
- Verify your token in `~/.openclaw/openclaw.json` under `gateway.auth.token`
- Check the Hammerspoon console for token parsing errors

### Health checks too frequent/infrequent
- Adjust `spoon.OpenclawHealth.checkInterval` (in seconds)

## Requirements

- [Hammerspoon](https://www.hammerspoon.org/) (tested with 0.9.100+)
- [OpenClaw](https://github.com/openclaw/openclaw) gateway
- `jq` (recommended, for reliable config parsing): `brew install jq`

## License

MIT License

## Author

KantaBai 💁‍♀️
