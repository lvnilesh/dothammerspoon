-- stretch.lua — sitting-break + KB reminder RECEIVER (no timers, no scheduler)
-- The clock lives in the Hermes container: a cron job fires on a 30-min grid
-- (+/- jitter, 8:00-23:59) and does both legs itself:
--   (1) POST to the self-hosted ntfy server (iPhone push — primary, always)
--   (2) ssh m1 -> /opt/homebrew/bin/hs -c 'require("stretch").banner(...)'
-- m1 sleeps whenever it wants and this Hammerspoon build has no wake hook, so
-- an in-app timer (the previous design) silently dropped fires. m1 is a dumb
-- receiver: it shows a zero-focus-steal hs.notify banner when told.

local stretch = {}

-- require is idempotent (cached); hs.* are lazy extensions.
pcall(require, "hs.notify")

function stretch.banner(title, subtitle, body)
  -- All three text args are MANDATORY strings in this build.
  title = title or "stretch break"
  subtitle = subtitle or "stretch + kettlebell break"
  body = body or ""
  local snd = nil
  local ok, s = pcall(function() return hs.sound.sound("Glass") end)
  if ok then snd = s end
  hs.notify.show(title, subtitle, body, nil, snd)
  print("[stretch] banner shown: " .. tostring(title))
  return 0
end

-- for manual testing: stretch.demo("TAG")
function stretch.demo(tag)
  return stretch.banner("TEST " .. (tag or "banner"), "stretch + kettlebell break",
    "Manual test from m1. If you see this, the receiver works.")
end

return stretch
