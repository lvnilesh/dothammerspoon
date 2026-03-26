--
-- Key binding setup for all modules and misc functionality
--
-- Uses Hyper (Shift+Ctrl+Alt+Cmd) for all bindings.
-- App launching is handled by Karabiner (O+key combos), not Hammerspoon.
-- Window management is bound in init.lua via MiroWindowsManager.
--
local bindings = {}

local uapp = require('utils.app')

local hyper = {'shift', 'ctrl', 'alt', 'cmd'}

function bindings.bind()
  -- toggle the hammerspoon console, focusing on the previous app when hidden
  local lastApp = nil
  local function toggleConsole()
    local frontmost = hs.application.frontmostApplication()
    hs.toggleConsole()
    if frontmost:bundleID() == 'org.hammerspoon.Hammerspoon' then
      if lastApp ~= nil then
        lastApp:activate()
        lastApp = nil
      end
    else
      lastApp = frontmost
    end
  end

  local function maximizeFrontmost()
    local win = hs.application.frontmostApplication():focusedWindow()
    if not win:isFullScreen() then win:maximize() end
  end

  -- module key bindings (all use Hyper)
  hs.fnutils.each({
    {key = '[',  fn = hsm.songs.prevTrack},
    {key = ']',  fn = hsm.songs.nextTrack},
    {key = '`',  fn = hsm.songs.rateSong0},
    {key = 'c',  fn = hsm.cheatsheet.cycle},
    {key = 'p',  fn = hsm.songs.playPause},
    {key = 'r',  fn = hs_reload},
    {key = 's',  fn = hsm.cheatsheet.toggle},
    {key = 't',  fn = hsm.songs.getInfo},
    {key = 'v',  fn = uapp.forcePaste},
    {key = 'x',  fn = hsm.cheatsheet.chooserToggle},
    {key = 'y',  fn = toggleConsole},
    {key = 'z',  fn = maximizeFrontmost},
  }, function(object)
    hs.hotkey.bind(hyper, object.key, object.fn)
  end)
end

return bindings
