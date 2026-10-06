-- stretch.lua — sitting-break + KB reminders (no focus steal)
-- Fires a small stretch/kettlebell routine every ~30 min with jitter, 8:00-23:59
-- daily. Each fire: (a) a macOS hs.notify banner (no keyboard focus) and
-- (b) an ntfy push to the iPhone (Apple Watch mirrors). Routine variety: each
-- fire picks randomly from the time-of-day pool; a related YouTube demo link
-- (chosen to match the routine) is appended to the push body.

local stretch = {}

-- Require every Hammerspoon extension this module touches. hs.* are lazy
-- extensions — an unrequired one is a nil field and indexing it throws at
-- load time (observed 2026-10-05: hs.event was nil -> init.lua load killed).
-- require is idempotent (cached), so re-requiring is always safe.
pcall(require, "hs.timer")
pcall(require, "hs.notify")

-- ---------------------------------------------------------------------------
-- Schedule: every 30 minutes, 8:00 -> 23:30 base, +/- jitter, daily.
-- ---------------------------------------------------------------------------
stretch.grid = 30            -- minutes between base fire times
stretch.window_start = 8 * 60     -- 8:00 first base
stretch.window_last = 23 * 60 + 30 -- 23:30 last base (within "through 11pm")
stretch.jitter = 4           -- +/- minutes of random offset per fire

-- ---------------------------------------------------------------------------
-- Routine pools by slot. Each entry: { title, lines, video }
-- video = YouTube search-URL whose query matches the routine (relevant demo).
-- ---------------------------------------------------------------------------
stretch.pools = {
  -- SLOT 1 ~ desk / low-effort stretches (no KB)
  {
    { title = "Desk Chest + Doorway Pec",
      lines = { "Stand, hands behind head, chest open - 30s",
        "Doorway pec stretch, each side 30s",
        "Wrist flexor rotation, 20 turns" },
      video = "https://www.youtube.com/results?search_query=doorway+pec+stretch+and+chest+open+stretch+desk" },
    { title = "Neck + Thoracic Reset",
      lines = { "Neck lateral lean, each side 20s",
        "Thoracic extension on chair back, 10 reps",
        "Chin tucks, 10 slow reps" },
      video = "https://www.youtube.com/results?search_query=neck+stretch+thoracic+extension+exercise+seated" },
    { title = "Shoulder + Wrist Wake-up",
      lines = { "Shoulder circles, 10 forward / 10 back",
        "Wrist flexor + extensor stretch, each 20s",
        "Overhead reach + side bend, each side 20s" },
      video = "https://www.youtube.com/results?search_query=shoulder+wrist+stretch+routine+office+desk" },
    { title = "Hip-Opener Seated Flow",
      lines = { "Seated figure-4 hip stretch, each side 30s",
        "Kneeling hip-flexor lunge, each side 30s",
        "Cat-cow on hands-and-knees, 10 reps" },
      video = "https://www.youtube.com/results?search_query=seated+hip+opener+stretch+routine+sitting+all+day" },
  },
  -- SLOT 2 ~ kettlebell circuits
  {
    { title = "KB Swing + Squat",
      lines = { "2x15 kettlebell swings",
        "2x10 goblet squats",
        "30s plank between sets" },
      video = "https://www.youtube.com/results?search_query=kettlebell+swing+and+goblet+squat+technique" },
    { title = "KB Clean + Dead Hang",
      lines = { "2x12 kettlebell cleans (each arm)",
        "Dead hang 20s x3",
        "10 bodyweight squats" },
      video = "https://www.youtube.com/results?search_query=kettlebell+clean+technique+and+dead+hang+grip" },
    { title = "KB Row + Core",
      lines = { "2x15 renegade rows",
        "30s plank",
        "10 dead bugs" },
      video = "https://www.youtube.com/results?search_query=renegade+row+kettlebell+core+plank+routine" },
    { title = "KB Farmer + Halo",
      lines = { "2x30s farmer carries (KB)",
        "10 KB halos each direction",
        "10 goblet squats" },
      video = "https://www.youtube.com/results?search_query=kettlebell+farmer+carry+and+halo+exercise+demo" },
  },
  -- SLOT 3 ~ evening stretch + light KB wind-down
  {
    { title = "Farmer + Overhead",
      lines = { "2x30s farmer carries (KB)",
        "Overhead triceps stretch, each side 30s",
        "10 goblet squats" },
      video = "https://www.youtube.com/results?search_query=overhead+triceps+stretch+and+farmer+carry" },
    { title = "KB Halo + Shoulder",
      lines = { "10 KB halos each direction",
        "Shoulder circles 15",
        "Child's pose 40s" },
      video = "https://www.youtube.com/results?search_query=kettlebell+halo+and+shoulder+mobility+stretch" },
    { title = "Evening Stretch Flow",
      lines = { "Hip-flexor lunge, each side 30s",
        "Pigeon pose, each side 30s",
        "Child's pose 60s + deep breaths" },
      video = "https://www.youtube.com/results?search_query=evening+full+body+stretch+routine+relax" },
    { title = "Lower-Back + Hip Reset",
      lines = { "Kneeling back extension, 10 reps",
        "Pigeon pose, each side 45s",
        "Dead bug, 8 slow reps" },
      video = "https://www.youtube.com/results?search_query=lower+back+relief+stretch+pigeon+pose+routine" },
  },
}

local function pick(pool)
  local n = #pool
  if n == 0 then return nil end
  return pool[math.random(1, n)]
end

-- pick a pool index by time-of-day so the mix is varied but sensible
local function slotFor(minOfDay)
  -- 8:00-13:00 desk stretches, 13:00-18:00 KB circuits, 18:00-23:59 evening
  if minOfDay < 13 * 60 then return 1
  elseif minOfDay < 18 * 60 then return 2
  else return 3 end
end

-- ---------------------------------------------------------------------------
-- ntfy push (the reliable leg; Apple Watch mirrors the iPhone).
-- ---------------------------------------------------------------------------
local ntfy_url = "https://ntfy.i.cloudgenius.app/stretch-92d2864f9942"

-- shell-quote: wrap in single quotes, escaping embedded single quotes.
-- The surrounding '%s' is MANDATORY — without it multi-line bodies get
-- word-split by sh (observed 2026-10-05: exit 127, "No such file").
local function esc(s)
  return ("'%s'"):format(s:gsub("'", "'\\''"))
end

local function push(title, body, clickUrl)
  -- curl SYNCHRONOUSLY (fast, <1s). Do NOT background it: a detached
  -- `nohup ... &` curl races the caller's process exit and can be killed
  -- before it runs (observed 2026-10-05: demo via `hs -c` intermittently
  -- never reached the server). Sync = deterministic + exit code visible.
  -- NOTE: needs macOS "Local Network" permission for Hammerspoon.
  -- Click: header makes the notification tappable (opens the demo video).
  local clickArg = ""
  if clickUrl then
    clickArg = " -H " .. esc("Click: " .. clickUrl)
  end
  local cmd = string.format(
    [[/usr/bin/curl -s -o /dev/null -w "%%{http_code}" -X POST --data %s -H %s -H %s -H %s%s --max-time 10 %s 2>>/tmp/stretch_curl_err.log]],
    esc(body), esc("Title: " .. title), esc("Priority: high"),
    esc("Tags: bell"), clickArg, esc(ntfy_url))
  local ok, success, reason, code = pcall(os.execute, "/bin/sh -c " .. esc(cmd))
  if not ok or not success then
    print("[stretch] push FAILED: " .. tostring(reason) .. " code=" .. tostring(code))
    return nil
  end
  return code
end

local function notify(routine)
  local snd = nil
  local ok, s = pcall(function() return hs.sound.sound("Glass") end)
  if ok then snd = s end
  local lines = table.concat(routine.lines, "\n")
  hs.notify.show(routine.title,
                 "stretch + kettlebell break",
                 lines,
                 nil, snd)
  -- push body: link FIRST (visible in the iOS notification banner, which
  -- truncates beyond ~2 lines), routine details below; Click header makes
  -- the notification tappable -> opens the demo video
  local body = lines
  if routine.video then
    body = routine.video .. "\n\n" .. lines
  end
  local code = push(routine.title, body, routine.video)
  print(string.format("[stretch] push rc=%s (0=delivered)", tostring(code)))
  return code
end

-- ---------------------------------------------------------------------------
-- Scheduling: 30-min grid within 8:00-23:59, +/- jitter, re-armed after each
-- fire. If Hammerspoon starts/resumes outside the window, wait to 8:00.
-- ---------------------------------------------------------------------------
local timer = nil
local nextFireEpoch = nil

local function nextBaseEpoch()
  -- smallest grid time (window_start + k*grid) strictly in the future today,
  -- or nil if past today's window_last (caller wraps to next day).
  local nowEpoch = os.time()
  local t = os.date("*t", nowEpoch)
  local curMin = t.hour * 60 + t.min
  local dayStart = os.time({ year = t.year, month = t.month, day = t.day,
                             hour = 0, min = 0, sec = 0 })
  local firstMin
  if curMin >= stretch.window_last then
    return nil
  end
  if curMin < stretch.window_start then
    firstMin = stretch.window_start
  else
    local k = math.floor((curMin - stretch.window_start) / stretch.grid) + 1
    -- k is the first grid point STRICTLY after now; if now lands exactly on a
    -- grid point that is still in window, prefer the next one (k as-is),
    -- otherwise the computed k. Both cases: k = floor(...)+1 works because
    -- curMin < window_last and grid divides the span, so firstMin lands on
    -- the next point; only re-check the window bound below.
    firstMin = stretch.window_start + k * stretch.grid
    if firstMin > stretch.window_last then
      -- now is between the last in-window point and window_last: if the last
      -- in-window point (23:30) is still ahead, fire it instead.
      firstMin = stretch.window_last
      if firstMin <= curMin then
        return nil
      end
    end
  end
  return dayStart + firstMin * 60
end

local STATUS_FILE = os.getenv("HOME") .. "/.hammerspoon/stretch.status"

local function writeStatus(line)
  -- pure file write: no focus steal, readable via ssh for verification
  pcall(function()
    local f = io.open(STATUS_FILE, "w")
    if f then f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. line .. "\n") f:close() end
  end)
end

local function inWindow(minOfDay)
  return minOfDay >= stretch.window_start and minOfDay <= 23 * 60 + 59
end

local function fire(slotIdx)
  local t = os.date("*t", os.time())
  local m = t.hour * 60 + t.min
  if not inWindow(m) then
    writeStatus(string.format("SKIP (outside window, minute=%s) re-arming", tostring(m)))
    return
  end
  local r = pick(stretch.pools[slotIdx])
  if r then notify(r) writeStatus("FIRED " .. r.title) end
end

local function arm()
  if timer then timer:stop() timer = nil end
  local base = nextBaseEpoch()
  local delay, slot
  if base == nil then
    -- past today's window -> wait to 8:00 tomorrow
    local t = os.date("*t", os.time())
    local tomorrow = os.time({ year = t.year, month = t.month, day = t.day + 1,
                               hour = math.floor(stretch.window_start / 60),
                               min = stretch.window_start % 60, sec = 0 })
    delay = tomorrow - os.time()
    slot = 1
  else
    delay = base - os.time()
    local bt = os.date("*t", base)
    slot = slotFor(bt.hour * 60 + bt.min)
  end
  -- jitter nudges the fire off the exact grid point (never across another
  -- grid point: capped to +/- jitter minutes)
  local jitterSec = math.random(-stretch.jitter, stretch.jitter) * 60
  delay = math.max(1, delay + jitterSec)
  nextFireEpoch = os.time() + delay
  timer = hs.timer.doAfter(delay, function()
    fire(slot)
    arm()
  end)
  writeStatus(string.format(
    "ARMED next_fire=%s in %ds (grid %s, jitter +/-%d min)",
    os.date("%H:%M:%S", nextFireEpoch), math.floor(delay), tostring(slot), stretch.jitter))
end

function stretch.start()
  math.randomseed(os.time())
  arm()
  -- NOTE: this Hammerspoon build (0.9.x) has NO hs.event extension — the
  -- wake-watcher attempt threw at line 277 on every load (2026-10-05).
  -- Sleep handling: stale timers that span sleep fire late; the in-window
  -- guard in fire() drops them, and arm() re-schedules from the current
  -- grid. A Mac asleep all day gets its first reminder at next wake.
  print("[stretch] reminders armed: every 30 min + jitter, 8:00-23:59 daily (no focus steal)")
end

-- for manual testing: stretch.demo(2, " (TEST)")
function stretch.demo(slot, titleSuffix)
  local r = pick(stretch.pools[slot])
  r.title = r.title .. (titleSuffix or "")
  local code = notify(r)
  return r.title, code
end

-- ops: report scheduler state (seconds until next fire, or nil if unarmed)
function stretch.nextFireIn()
  if not timer or not timer:isRunning() or not nextFireEpoch then return nil end
  return math.max(0, nextFireEpoch - os.time())
end

return stretch
