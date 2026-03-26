-- OpenclawHealth.spoon
-- A Hammerspoon spoon to monitor the Openclaw Main Gateway health in the macOS menu bar
-- Monitors a remote gateway via HTTP health checks (no local process management)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "OpenclawHealth"
obj.version = "4.0"
obj.author = "@LVNilesh"
obj.homepage = "https://github.com/openclaw/openclaw"
obj.license = "MIT"

--- OpenclawHealth.checkInterval
--- Variable
--- How often to check health (in seconds). Default: 30
obj.checkInterval = 30

--- OpenclawHealth.gatewayUrl
--- Variable
--- The base URL of the main gateway (Tailscale TLS). Set via secrets.lua in init.lua.
obj.gatewayUrl = nil

--- OpenclawHealth.dashboardUrl
--- Variable
--- The URL of the Web UI dashboard (Traefik proxy). Set via secrets.lua in init.lua.
obj.dashboardUrl = nil

--- OpenclawHealth.authToken
--- Variable
--- Auth token for the gateway Web UI. Set this in init.lua.
obj.authToken = nil

--- OpenclawHealth.icons
--- Variable
--- Icons for different states (using SF Symbols or emoji)
obj.icons = {
  healthy = "🟢",
  warning = "🟡",
  error = "🔴",
  unknown = "⚪"
}

-- Internal state
obj.menubar = nil
obj.timer = nil
obj.ws = nil
obj.lastStatus = "unknown"
obj.lastCheck = nil
obj.lastError = nil

--- OpenclawHealth:getBaseUrl()
--- Method
--- Get the base URL of the main gateway
--- Returns: string
function obj:getBaseUrl()
  return self.gatewayUrl
end

--- OpenclawHealth:getWebUIUrl()
--- Method
--- Get the Web UI URL with authentication token if available
--- Returns: string
function obj:getWebUIUrl()
  local baseUrl = self.dashboardUrl

   if self.authToken and self.authToken ~= "" then
    return baseUrl .. "/#token=" .. self.authToken
  end

  return baseUrl
end

--- OpenclawHealth:performHealthCheck()
--- Method
--- Perform a WebSocket health check against the main gateway and update status.
--- Opens a wss:// connection; if the handshake succeeds the gateway is alive.
function obj:performHealthCheck()
  self.lastCheck = os.date("%H:%M:%S")

  -- Close any lingering probe from a previous check
  if self.ws then
    self.ws:close()
    self.ws = nil
  end

  local url = self:getBaseUrl()

  -- Timeout: if we haven't heard back in 10s, mark as error
  local timedOut = false
  local checkTimer = hs.timer.doAfter(10, function()
    timedOut = true
    if self.ws then
      self.ws:close()
      self.ws = nil
    end
    self.lastStatus = "error"
    self.lastError = "Timeout (10s)"
    self:updateMenubar()
  end)

  self.ws = hs.websocket.new(url, function(event, message)
    if timedOut then return end
    checkTimer:stop()

    if event == "open" then
      self.lastStatus = "healthy"
      self.lastError = nil
    elseif event == "fail" then
      self.lastStatus = "error"
      self.lastError = "Connection failed"
    elseif event == "closed" then
      -- If we already marked healthy, keep it; otherwise mark error
      if self.lastStatus ~= "healthy" then
        self.lastStatus = "error"
        self.lastError = "Connection closed"
      end
    end

    -- Close the probe connection (we only needed the handshake)
    if event == "open" and self.ws then
      self.ws:close()
      self.ws = nil
    end

    self:updateMenubar()
  end)
end

--- OpenclawHealth:updateMenubar()
--- Method
--- Update the menubar icon and tooltip
function obj:updateMenubar()
  if not self.menubar then return end

  local icon = self.icons[self.lastStatus] or self.icons.unknown
  self.menubar:setTitle(icon)

  -- Build menu
  local menu = {}

  -- Status header
  local statusText = "Main Gateway"
  if self.lastStatus == "healthy" then
    statusText = statusText .. ": Alive ✓"
  elseif self.lastStatus == "warning" then
    statusText = statusText .. ": Warning ⚠"
  elseif self.lastStatus == "error" then
    statusText = statusText .. ": Down ✗"
  else
    statusText = statusText .. ": Unknown"
  end

  table.insert(menu, { title = statusText, disabled = true })
  table.insert(menu, { title = "-" })

  -- Host info
  table.insert(menu, { title = "Gateway: " .. self.gatewayUrl, disabled = true })
  table.insert(menu, { title = "Dashboard: " .. self.dashboardUrl, disabled = true })

  -- Last check time
  if self.lastCheck then
    table.insert(menu, { title = "Last check: " .. self.lastCheck, disabled = true })
  end

  -- Error if any
  if self.lastError then
    table.insert(menu, { title = "Error: " .. self.lastError, disabled = true })
  end

  table.insert(menu, { title = "-" })

  -- Actions
  table.insert(menu, {
    title = "Check Now",
    fn = function() self:performHealthCheck() end
  })

  table.insert(menu, {
    title = "Open Web UI",
    fn = function()
      local url = self:getWebUIUrl()
      hs.execute('open "' .. url .. '"')
    end
  })

  self.menubar:setMenu(menu)
end

--- OpenclawHealth:start()
--- Method
--- Start the health monitoring
function obj:start()
  if self.menubar then
    self:stop()
  end

  -- Create menubar item
  self.menubar = hs.menubar.new()
  self.menubar:setTitle(self.icons.unknown)

  -- Do initial check
  self:performHealthCheck()

  -- Start periodic timer
  self.timer = hs.timer.doEvery(self.checkInterval, function()
    self:performHealthCheck()
  end)

  return self
end

--- OpenclawHealth:stop()
--- Method
--- Stop the health monitoring
function obj:stop()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end

  if self.ws then
    self.ws:close()
    self.ws = nil
  end

  if self.menubar then
    self.menubar:delete()
    self.menubar = nil
  end

  return self
end

--- OpenclawHealth:init()
--- Method
--- Initialize the spoon
function obj:init()
  -- Nothing to do on init
  return self
end

return obj
