local LOGLEVEL = 'info'

-- require('position')

local hyper = {"shift", "ctrl", "alt", "cmd"}

local secrets = require('secrets')

hs.loadSpoon("MiroWindowsManager")
hs.loadSpoon("OpenclawHealth")

-- Start Openclaw Main Gateway health monitoring (Tailscale TLS direct)
spoon.OpenclawHealth.checkInterval = 30  -- check every 30 seconds
spoon.OpenclawHealth.gatewayUrl = secrets.openclaw_gateway_url
spoon.OpenclawHealth.dashboardUrl = secrets.openclaw_dashboard_url
spoon.OpenclawHealth.authToken = secrets.openclaw_auth_token
spoon.OpenclawHealth:start()

hs.window.animationDuration = 0

amphetamine = require "amphetamine"

--- Ultra-wide configuration for Dell U5226KW (6144x2560, 2.4:1 aspect ratio)
--- On this ultra-wide, a "half" (1/2) is 1536pt wide -- wider than most full monitors.
--- So we cycle: 1/2 -> 1/3 -> 1/4 -> 1/6 for directional tiling.
spoon.MiroWindowsManager.sizes = {2, 3, 4, 6}
spoon.MiroWindowsManager.fullScreenSizes = {1, 4/3, 2, 3}

spoon.MiroWindowsManager:bindHotkeys({
  -- Directional tiling (arrows cycle through 1/2, 1/3, 1/4, 1/6)
  up         = {hyper, "up"},
  right      = {hyper, "right"},
  down       = {hyper, "down"},
  left       = {hyper, "left"},
  -- Fullscreen cycling (full -> 3/4 centered -> 1/2 centered)
  fullscreen = {hyper, "f"},
  -- Center window at its current size
  middle     = {hyper, "m"},
  -- Move to next screen (for your secondary MACROSILICON display)
  nextscreen = {hyper, "n"},

  -- === ULTRA-WIDE COLUMN ZONES ===
  -- Column 1/2/3: place in left/center/right third (cycle to 1/4, 1/6)
  col1       = {hyper, "1"},
  col2       = {hyper, "2"},
  col3       = {hyper, "3"},
  -- Left 2/3 and Right 2/3 (cycle to 3/4)
  twothirdL  = {hyper, "4"},
  twothirdR  = {hyper, "5"},
  -- Center column cycling: 1/3 -> 1/2 -> 2/3 centered
  centerCycle = {hyper, "6"},

  -- === QUADRANT ZONES (corners) ===
  -- Each cycles: half-by-half -> third-by-half
  topleft     = {hyper, "q"},
  topright    = {hyper, "w"},
  bottomleft  = {hyper, "a"},
  bottomright = {hyper, "d"},

  -- === 2x3 GRID (6 zones: top/bottom x left/center/right thirds) ===
  -- Top row: U/I/O, Bottom row: 7/8/9 (J/K/L consumed by Karabiner vim nav)
  topthirdL   = {hyper, "u"},
  topthirdM   = {hyper, "i"},
  topthirdR   = {hyper, "o"},
  botthirdL   = {hyper, "7"},
  botthirdM   = {hyper, "8"},
  botthirdR   = {hyper, "9"},

  -- === NUDGE (slide window keeping its size) ===
  nudgeLeft   = {hyper, "-"},
  nudgeRight  = {hyper, "="},
})

-- List of modules to load (found in modules/ dir)
local modules = {
  'appwindows',
  'browser',
  'cheatsheet',
  'songs',
  'weather',
  'wifi',
  'worktime',
}

-- global modules namespace (short for easy console use)
hsm = {}

-- load module configuration
local cfg = require('config')
hsm.cfg = cfg.global

-- global log
hsm.log = hs.logger.new(hs.host.localizedName(), LOGLEVEL)

-- load a module from modules/ dir, and set up a logger for it
local function loadModuleByName(modName)
  hsm[modName] = require('modules.' .. modName)
  hsm[modName].name = modName
  hsm[modName].log = hs.logger.new(modName, LOGLEVEL)
  hsm.log.i(hsm[modName].name .. ': module loaded')
end

-- save the configuration of a module in the module object
local function configModule(mod)
  mod.cfg = mod.cfg or {}
  if (cfg[mod.name]) then
    for k,v in pairs(cfg[mod.name]) do mod.cfg[k] = v end
    hsm.log.i(mod.name .. ': module configured')
  end
end

-- start a module
local function startModule(mod)
  if mod.start == nil then return end
  mod.start()
  hsm.log.i(mod.name .. ': module started')
end

-- stop a module
local function stopModule(mod)
  if mod.stop == nil then return end
  mod.stop()
  hsm.log.i(mod.name .. ': module stopped')
end

-- load, configure, and start each module
hs.fnutils.each(modules, loadModuleByName)
hs.fnutils.each(hsm, configModule)
hs.fnutils.each(hsm, startModule)

-- global function to stop modules and reload hammerspoon config
function hs_reload()
  hs.fnutils.each(hsm, stopModule)
  hs.reload()
end

-- load and bind key bindings
local bindings = require('bindings')
bindings.bind()

-- Disable all window animations
hs.window.animationDuration = 0

hs.alert.show('Hammerspoon Config Loaded', 1)
