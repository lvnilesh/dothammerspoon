-- module: weather
-- Use the Open-Meteo API (free, no key required) to display local weather
-- in a menubar item. Replaces the defunct Dark Sky API.
--
local m = {}

local ufile = require('utils.file')

-- Open-Meteo WMO weather condition codes to icon/description mapping
local WMO_CODES = {
  [0]  = {icon = "clear-day",         desc = "Clear sky"},
  [1]  = {icon = "clear-day",         desc = "Mainly clear"},
  [2]  = {icon = "partly-cloudy-day", desc = "Partly cloudy"},
  [3]  = {icon = "cloudy",            desc = "Overcast"},
  [45] = {icon = "fog",               desc = "Fog"},
  [48] = {icon = "fog",               desc = "Depositing rime fog"},
  [51] = {icon = "rain",              desc = "Light drizzle"},
  [53] = {icon = "rain",              desc = "Moderate drizzle"},
  [55] = {icon = "rain",              desc = "Dense drizzle"},
  [56] = {icon = "sleet",             desc = "Light freezing drizzle"},
  [57] = {icon = "sleet",             desc = "Dense freezing drizzle"},
  [61] = {icon = "rain",              desc = "Slight rain"},
  [63] = {icon = "rain",              desc = "Moderate rain"},
  [65] = {icon = "rain",              desc = "Heavy rain"},
  [66] = {icon = "sleet",             desc = "Light freezing rain"},
  [67] = {icon = "sleet",             desc = "Heavy freezing rain"},
  [71] = {icon = "snow",              desc = "Slight snowfall"},
  [73] = {icon = "snow",              desc = "Moderate snowfall"},
  [75] = {icon = "snow",              desc = "Heavy snowfall"},
  [77] = {icon = "snow",              desc = "Snow grains"},
  [80] = {icon = "rain",              desc = "Slight rain showers"},
  [81] = {icon = "rain",              desc = "Moderate rain showers"},
  [82] = {icon = "rain",              desc = "Violent rain showers"},
  [85] = {icon = "snow",              desc = "Slight snow showers"},
  [86] = {icon = "snow",              desc = "Heavy snow showers"},
  [95] = {icon = "thunderstorm",      desc = "Thunderstorm"},
  [96] = {icon = "thunderstorm",      desc = "Thunderstorm with slight hail"},
  [99] = {icon = "thunderstorm",      desc = "Thunderstorm with heavy hail"},
}

local function wmoInfo(code)
  return WMO_CODES[code] or {icon = "default", desc = "Unknown"}
end

local function adjustIconForTime(icon, hour, sr_hour, ss_hour)
  sr_hour = sr_hour or 6
  ss_hour = ss_hour or 18
  if hour < sr_hour or hour >= ss_hour then
    if icon == "clear-day" then return "clear-night" end
    if icon == "partly-cloudy-day" then return "partly-cloudy-night" end
  end
  return icon
end

local menu = nil
local loc = nil
local fetchTimer = nil

local function totemp(deg) return string.format('%.0f°', deg) end
local function cToF(c) return c * 9.0 / 5.0 + 32 end

local function isoToHour(s)
  return tonumber(s:sub(12, 13)) or 0
end

local function formatTime(s)
  if not s then return "?" end
  local h, mn = s:match("T(%d+):(%d+)")
  if not h then return s end
  h = tonumber(h)
  local ampm = h >= 12 and "pm" or "am"
  if h == 0 then h = 12
  elseif h > 12 then h = h - 12 end
  return string.format("%d:%s%s", h, mn, ampm)
end

local function formatHour(h)
  local ampm = h >= 12 and "pm" or "am"
  local dh = h
  if dh == 0 then dh = 12
  elseif dh > 12 then dh = dh - 12 end
  return string.format("%d%s", dh, ampm)
end

local function buildMenu(data)
  if not data or not data.current then
    return {{title = "No data", disabled = true}}
  end

  local menuTable = {}
  local current = data.current
  local temp_f = cToF(current.temperature_2m or 0)
  local apparent_f = cToF(current.apparent_temperature or 0)
  local code = current.weather_code or 0
  local info = wmoInfo(code)

  local prefix = ""
  if totemp(apparent_f) ~= totemp(temp_f) then prefix = "~" end

  local currentLine = string.format("Now: %s%s  %s", prefix, totemp(apparent_f), info.desc)
  if current.relative_humidity_2m then
    currentLine = currentLine .. string.format("  %d%% humidity", current.relative_humidity_2m)
  end
  if current.wind_speed_10m then
    currentLine = currentLine .. string.format("  %.0f mph wind", current.wind_speed_10m * 0.621371)
  end
  table.insert(menuTable, {title = currentLine})

  -- Sunrise/Sunset
  if data.daily and data.daily.sunrise and data.daily.sunset then
    local sunrise = formatTime(data.daily.sunrise[1])
    local sunset = formatTime(data.daily.sunset[1])
    table.insert(menuTable, {
      title = string.format("Sunrise: %s  Sunset: %s", sunrise, sunset),
      disabled = true
    })
  end

  table.insert(menuTable, {title = "-"})

  -- Hourly forecast (next 24 hours)
  if data.hourly and data.hourly.time then
    local hourlyMenu = {}
    local now_hour = tonumber(os.date("%H"))
    local start_idx = now_hour + 1

    for i = start_idx, math.min(start_idx + 23, #data.hourly.time) do
      local h_apparent = cToF(data.hourly.apparent_temperature[i] or 0)
      local h_temp = cToF(data.hourly.temperature_2m[i] or 0)
      local h_code = data.hourly.weather_code[i] or 0
      local h_info = wmoInfo(h_code)
      local h_precip = data.hourly.precipitation_probability[i] or 0
      local h_hour = isoToHour(data.hourly.time[i])
      local h_prefix = ""
      if totemp(h_apparent) ~= totemp(h_temp) then h_prefix = "~" end

      local line = string.format("%5s: %s%5s  %s",
        formatHour(h_hour), h_prefix, totemp(h_apparent), h_info.desc)
      if h_precip > 25 then
        line = line .. string.format("  %d%% precip", h_precip)
      end

      if h_hour == 0 then
        table.insert(hourlyMenu, {title = "-"})
      end
      table.insert(hourlyMenu, {title = line})
    end

    table.insert(menuTable, {
      title = "Hourly Forecast",
      menu = hourlyMenu,
    })
  end

  table.insert(menuTable, {title = "-"})

  -- Daily forecast (7 days)
  if data.daily and data.daily.time then
    for i = 1, #data.daily.time do
      local d_hi = cToF(data.daily.temperature_2m_max[i] or 0)
      local d_lo = cToF(data.daily.temperature_2m_min[i] or 0)
      local d_code = data.daily.weather_code[i] or 0
      local d_info = wmoInfo(d_code)
      local d_precip = data.daily.precipitation_probability_max[i] or 0

      local dayname = os.date("%a", os.time() + (i - 1) * 86400)
      local line = string.format("%4s: %5s/%5s  %s",
        dayname, totemp(d_hi), totemp(d_lo), d_info.desc)
      if d_precip > 25 then
        line = line .. string.format("  %d%% precip", d_precip)
      end

      table.insert(menuTable, {title = line})
    end
  end

  return menuTable
end

local function updateMenu(data)
  if menu == nil then return end

  local iconPath = ufile.toPath(m.cfg.iconPath, 'default.pdf')

  if data and data.current then
    local temp_f = cToF(data.current.temperature_2m or 0)
    local apparent_f = cToF(data.current.apparent_temperature or 0)
    local code = data.current.weather_code or 0
    local info = wmoInfo(code)
    local prefix = ""
    if totemp(apparent_f) ~= totemp(temp_f) then prefix = "~" end

    local hour = tonumber(os.date("%H"))
    local sr_hour, ss_hour = 6, 18
    if data.daily and data.daily.sunrise and data.daily.sunrise[1] then
      sr_hour = isoToHour(data.daily.sunrise[1])
      ss_hour = isoToHour(data.daily.sunset[1])
    end
    local iconName = adjustIconForTime(info.icon, hour, sr_hour, ss_hour)
    local testPath = ufile.toPath(m.cfg.iconPath, iconName .. '.pdf')
    if ufile.exists(testPath) then iconPath = testPath end

    menu:setTitle(string.format('%s%s', prefix, totemp(apparent_f)))
    menu:setMenu(buildMenu(data))
  end

  menu:setIcon(iconPath)

  if loc and loc.name then
    menu:setTooltip(loc.name)
  elseif loc then
    menu:setTooltip(string.format("%.4f, %.4f", loc.latitude, loc.longitude))
  end
end

local function fetchWeather()
  if loc == nil then return end

  local url = string.format(
    "https://api.open-meteo.com/v1/forecast?"
    .. "latitude=%.4f&longitude=%.4f"
    .. "&current=temperature_2m,apparent_temperature,relative_humidity_2m,"
    .. "weather_code,wind_speed_10m"
    .. "&hourly=temperature_2m,apparent_temperature,weather_code,"
    .. "precipitation_probability"
    .. "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
    .. "sunrise,sunset,precipitation_probability_max"
    .. "&temperature_unit=celsius"
    .. "&wind_speed_unit=kmh"
    .. "&timezone=auto"
    .. "&forecast_days=7",
    loc.latitude, loc.longitude
  )

  hs.http.asyncGet(url, nil, function(status, body, headers)
    if status < 0 or not body then
      m.log.e("Weather fetch failed: " .. tostring(status))
      return
    end

    local data = hs.json.decode(body)
    if not data then
      m.log.e("Failed to decode weather JSON")
      return
    end

    updateMenu(data)
  end)
end

local function reverseGeocode()
  if loc == nil then return end

  local url = string.format(
    "https://nominatim.openstreetmap.org/reverse?format=json&lat=%.4f&lon=%.4f",
    loc.latitude, loc.longitude
  )

  hs.http.asyncGet(url, {["User-Agent"] = "Hammerspoon-Weather/1.0"}, function(status, body, headers)
    if status < 0 or not body then return end
    local data = hs.json.decode(body)
    if data and data.display_name then
      local parts = {}
      for part in data.display_name:gmatch("[^,]+") do
        parts[#parts + 1] = part:match("^%s*(.-)%s*$")
      end
      if #parts >= 3 then
        loc.name = parts[1] .. ", " .. parts[3]
      else
        loc.name = data.display_name
      end
    end
  end)
end

-- Get location via IP geolocation (no hs.location needed, avoids segfaults)
local function fetchLocation(callback)
  hs.http.asyncGet("https://ipinfo.io/json", nil, function(status, body, headers)
    if status < 0 or not body then
      m.log.e("IP geolocation failed: " .. tostring(status))
      callback(nil)
      return
    end
    local data = hs.json.decode(body)
    if data and data.loc then
      local lat, lon = data.loc:match("([^,]+),([^,]+)")
      if lat and lon then
        loc = {latitude = tonumber(lat), longitude = tonumber(lon)}
        loc.name = (data.city or "") .. ", " .. (data.region or "")
        callback(loc)
        return
      end
    end
    m.log.e("Could not parse location from ipinfo.io")
    callback(nil)
  end)
end

function m.start()
  menu = hs.menubar.new()
  if menu == nil then
    m.log.e("Failed to create menubar item")
    return
  end
  menu:setTitle("...")

  fetchLocation(function(location)
    if location then
      reverseGeocode()
      fetchWeather()
    else
      menu:setTitle("No Loc")
    end
  end)

  fetchTimer = hs.timer.new(m.cfg.fetchTimeout, function()
    if loc then fetchWeather() end
  end)
  fetchTimer:start()
end

function m.stop()
  if menu then menu:delete() end
  if fetchTimer then fetchTimer:stop() end

  menu = nil
  fetchTimer = nil
  loc = nil
end

return m
