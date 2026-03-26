-- copy this file to config.lua and edit as needed
--
local cfg = {}
cfg.global = {}  -- this will be accessible via hsm.cfg in modules
----------------------------------------------------------------------------

local ufile = require('utils.file')

local E = require('hs.application.watcher')   -- appwindows events
local A = require('appactions')               -- appwindows actions

-- Monospace font used in multiple modules
local MONOFONT = 'Menlo'

--------------------
--  global paths  --
--------------------
cfg.global.paths = {}
cfg.global.paths.base  = os.getenv('HOME')
cfg.global.paths.tmp   = os.getenv('TMPDIR')
cfg.global.paths.bin   = ufile.toPath(cfg.global.paths.base, 'bin')
cfg.global.paths.cloud = ufile.toPath(cfg.global.paths.base, 'Dropbox')
cfg.global.paths.hs    = ufile.toPath(cfg.global.paths.base, '.hammerspoon')
cfg.global.paths.data  = ufile.toPath(cfg.global.paths.hs,   'data')
cfg.global.paths.media = ufile.toPath(cfg.global.paths.hs,   'media')
cfg.global.paths.ul    = '/usr/local'
cfg.global.paths.ulbin = ufile.toPath(cfg.global.paths.ul,   'bin')

------------------
--  appwindows  --
------------------
-- Each app name points to a list of rules, which are event/action pairs.
-- See hs.application.watcher for events, and appactions.lua for actions.
cfg.appwindows = {
  rules = {
    Finder              = {{evt = E.activated,    act = A.toFront}},
    ['Google Chrome']   = {{evt = E.launched,     act = A.maximize}},
    Skype               = {{evt = E.launched,     act = A.fullscreen}},
  },
}

---------------
--  battery  --
---------------
cfg.battery = {
  icon = ufile.toPath(cfg.global.paths.media, 'battery.png'),
}

---------------
--  browser  --
---------------
cfg.browser = {
  apps = {
    ['com.apple.Safari'] = true,
    ['com.google.Chrome'] = true,
    ['org.mozilla.firefox'] = true,
    ['com.electron.brave'] = true,
    ['company.thebrowser.Browser'] = true,
  },
}

cfg.browser.defaultApp = 'company.thebrowser.Browser'

------------------
--  cheatsheet  --
------------------
cfg.cheatsheet = {
  defaultName = 'default',
  chooserWidth = 50,
  maxParts = 3,
  path = {
    dir    = ufile.toPath(cfg.global.paths.hs, 'cheatsheets'),
    css    = ufile.toPath(cfg.global.paths.media, 'cheatsheet.min.css'),
    pandoc = ufile.toPath(cfg.global.paths.ulbin, 'pandoc'),
  },
}

-------------
--  songs  --
-------------
cfg.songs = {
  -- set this to the path of the track binary if you're using it
  -- trackBinary = ufile.toPath(cfg.global.paths.bin, 'track'),
  trackBinary = nil,
  -- set this to the path of the track database file if not default
  -- trackDB = ufile.toPath(cfg.global.paths.cloud, 'track.db'),
  trackDB = nil,
}

---------------
--  weather  --
---------------
cfg.weather = {
  fetchTimeout = 120,             -- timeout for downloading weather data
  iconPath = ufile.toPath(cfg.global.paths.media, 'weather'),
}

------------
--  wifi  --
------------
cfg.wifi = {
  icon = ufile.toPath(cfg.global.paths.media, 'airport.png'),
}

----------------
--  worktime  --
----------------
cfg.worktime = {
  menupriority = 1380,            -- menubar priority (lower is lefter)
  awareness = {
    time = {
      chimeAfter  = 30,           -- mins
      chimeRepeat = 4,            -- seconds between repeated chimes
    },
    chime = {
      file = ufile.toPath(cfg.global.paths.media, 'bowl.wav'),
      volume = 0.4,
    },
  },
  pomodoro = {
    time = {
      work = 25,  -- mins
      rest = 5,   -- mins
    },
    chime = {
      file = ufile.toPath(cfg.global.paths.media, 'temple.mp3'),
      volume = 1.0,
    },
  },
}


----------------------------------------------------------------------------
return cfg
