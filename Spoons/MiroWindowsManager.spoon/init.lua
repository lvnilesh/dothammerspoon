-- Copyright (c) 2018 Miro Mannino
-- Extended for ultra-wide monitor support (Dell U5226KW 6144x2560 / 2.4:1)
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this
-- software and associated documentation files (the "Software"), to deal in the Software
-- without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

--- === MiroWindowsManager ===
---
--- Window tiling manager with ultra-wide monitor support.
--- Supports directional tiling, column-based zones, and quadrant placement.
--- Optimized for ultra-wide displays (2.4:1 and wider) while remaining
--- compatible with standard 16:9 screens.
---
--- Official homepage: [https://github.com/miromannino/miro-windows-manager](https://github.com/miromannino/miro-windows-manager)
---

local obj={}
obj.__index = obj

-- Metadata
obj.name = "MiroWindowsManager"
obj.version = "2.0"
obj.author = "Miro Mannino <miro.mannino@gmail.com>, extended for ultra-wide"
obj.homepage = "https://github.com/miromannino/miro-windows-management"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- MiroWindowsManager.sizes
--- Variable
--- The sizes that the window can have when tiling to an edge.
--- The sizes are expressed as dividend of the entire screen's size.
--- For example `{2, 3, 4, 6}` means it cycles through 1/2, 1/3, 1/4, 1/6.
obj.sizes = {2, 3, 4, 6}

--- MiroWindowsManager.fullScreenSizes
--- Variable
--- The sizes that the window can have in full-screen.
--- For example `{1, 4/3, 2, 3}` means full, 3/4 centered, 1/2 centered, 1/3 centered.
obj.fullScreenSizes = {1, 4/3, 2, 3}

--- MiroWindowsManager.GRID
--- Variable
--- The screen's grid size using `hs.grid.setGrid()`
--- Using 24x24 allows clean divisions into halves, thirds, quarters, sixths, eighths.
obj.GRID = {w = 24, h = 24}

obj._pressed = {
  up = false,
  down = false,
  left = false,
  right = false
}

-- ============================================================================
-- CORE: Directional tiling (Left/Right/Up/Down arrows)
-- Cycles through sizes when pressed repeatedly
-- ============================================================================

function obj:_nextStep(dim, offs, cb)
  if hs.window.focusedWindow() then
    local axis = dim == 'w' and 'x' or 'y'
    local oppDim = dim == 'w' and 'h' or 'w'
    local oppAxis = dim == 'w' and 'y' or 'x'
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    local nextSize = self.sizes[1]
    for i=1,#self.sizes do
      if cell[dim] == self.GRID[dim] / self.sizes[i] and
        (cell[axis] + (offs and cell[dim] or 0)) == (offs and self.GRID[dim] or 0)
        then
          nextSize = self.sizes[(i % #self.sizes) + 1]
        break
      end
    end

    cb(cell, nextSize)
    if cell[oppAxis] ~= 0 and cell[oppAxis] + cell[oppDim] ~= self.GRID[oppDim] then
      cell[oppDim] = self.GRID[oppDim]
      cell[oppAxis] = 0
    end

    hs.grid.set(win, cell, screen)
  end
end

-- ============================================================================
-- CORE: Fullscreen cycling (centered window at various sizes)
-- ============================================================================

function obj:_nextFullScreenStep()
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    local nextSize = self.fullScreenSizes[1]
    for i=1,#self.fullScreenSizes do
      if cell.w == self.GRID.w / self.fullScreenSizes[i] and
         cell.h == self.GRID.h / self.fullScreenSizes[i] and
         cell.x == (self.GRID.w - self.GRID.w / self.fullScreenSizes[i]) / 2 and
         cell.y == (self.GRID.h - self.GRID.h / self.fullScreenSizes[i]) / 2 then
        nextSize = self.fullScreenSizes[(i % #self.fullScreenSizes) + 1]
        break
      end
    end

    cell.w = self.GRID.w / nextSize
    cell.h = self.GRID.h / nextSize
    cell.x = (self.GRID.w - self.GRID.w / nextSize) / 2
    cell.y = (self.GRID.h - self.GRID.h / nextSize) / 2

    hs.grid.set(win, cell, screen)
  end
end

-- ============================================================================
-- CORE: Move to next screen
-- ============================================================================

function obj:_moveNextScreenStep()
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
  end
end

-- ============================================================================
-- CORE: Expand to full dimension (when opposing arrows pressed simultaneously)
-- ============================================================================

function obj:_fullDimension(dim)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    cell = hs.grid.get(win, screen)

    if (dim == 'x') then
      cell = '0,0 ' .. self.GRID.w .. 'x' .. self.GRID.h
    else
      cell[dim] = self.GRID[dim]
      cell[dim == 'w' and 'x' or 'y'] = 0
    end

    hs.grid.set(win, cell, screen)
  end
end

-- ============================================================================
-- NEW: Column-based zone placement for ultra-wide monitors
-- Places window in a specific column region of the screen
-- x, w are expressed in grid units (out of GRID.w = 24)
-- ============================================================================

function obj:_placeInZone(x, y, w, h)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local screen = win:screen()
    local cell = hs.geometry.new(x, y, w, h)
    hs.grid.set(win, cell, screen)
  end
end

--- Place window in a column zone that cycles through sizes on repeated press.
--- zones is a list of {x, y, w, h} grid specs to cycle through.
function obj:_cycleZones(zones)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local screen = win:screen()
    local cell = hs.grid.get(win, screen)

    local nextZone = zones[1]
    for i = 1, #zones do
      local z = zones[i]
      if cell.x == z[1] and cell.y == z[2] and cell.w == z[3] and cell.h == z[4] then
        nextZone = zones[(i % #zones) + 1]
        break
      end
    end

    local newCell = hs.geometry.new(nextZone[1], nextZone[2], nextZone[3], nextZone[4])
    hs.grid.set(win, newCell, screen)
  end
end

-- ============================================================================
-- NEW: Nudge window left/right by one grid column, keeping size
-- Wraps around when hitting screen edges
-- ============================================================================

function obj:_nudge(direction)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local screen = win:screen()
    local cell = hs.grid.get(win, screen)
    local step = self.GRID.w / 6  -- nudge by 1/6 screen (4 grid units)

    if direction == 'right' then
      cell.x = cell.x + step
      if cell.x + cell.w > self.GRID.w then cell.x = 0 end
    elseif direction == 'left' then
      cell.x = cell.x - step
      if cell.x < 0 then cell.x = self.GRID.w - cell.w end
    end

    hs.grid.set(win, cell, screen)
  end
end

-- ============================================================================
-- HOTKEY BINDING
-- ============================================================================

--- MiroWindowsManager:bindHotkeys()
--- Method
--- Binds hotkeys for Miro's Windows Manager (with ultra-wide extensions)
--- Parameters:
---  * mapping - A table containing hotkey details for the following items:
---   * up, down, left, right: directional tiling (cycles through sizes)
---   * fullscreen: centered fullscreen cycling
---   * middle: center window on screen
---   * nextscreen: move window to next monitor
---   * col1, col2, col3: place in 1/3 column zones
---   * twothirdL, twothirdR: left 2/3 or right 2/3
---   * centerCycle: center column cycling (1/3 -> 1/2 centered)
---   * topleft, topright, bottomleft, bottomright: quadrant placement
---   * topthirdL, topthirdM, topthirdR: top-half third columns
---   * botthirdL, botthirdM, botthirdR: bottom-half third columns
function obj:bindHotkeys(mapping)
  hs.inspect(mapping)
  print("Bind Hotkeys for Miro's Windows Manager (Ultra-Wide Edition)")

  local G = self.GRID

  -- ---- Directional tiling (existing, enhanced with more sizes) ----

  hs.hotkey.bind(mapping.down[1], mapping.down[2], function ()
    self._pressed.down = true
    if self._pressed.up then
      self:_fullDimension('h')
    else
      self:_nextStep('h', true, function (cell, nextSize)
        cell.y = self.GRID.h - self.GRID.h / nextSize
        cell.h = self.GRID.h / nextSize
      end)
    end
  end, function ()
    self._pressed.down = false
  end)

  hs.hotkey.bind(mapping.right[1], mapping.right[2], function ()
    self._pressed.right = true
    if self._pressed.left then
      self:_fullDimension('w')
    else
      self:_nextStep('w', true, function (cell, nextSize)
        cell.x = self.GRID.w - self.GRID.w / nextSize
        cell.w = self.GRID.w / nextSize
      end)
    end
  end, function ()
    self._pressed.right = false
  end)

  hs.hotkey.bind(mapping.left[1], mapping.left[2], function ()
    self._pressed.left = true
    if self._pressed.right then
      self:_fullDimension('w')
    else
      self:_nextStep('w', false, function (cell, nextSize)
        cell.x = 0
        cell.w = self.GRID.w / nextSize
      end)
    end
  end, function ()
    self._pressed.left = false
  end)

  hs.hotkey.bind(mapping.up[1], mapping.up[2], function ()
    self._pressed.up = true
    if self._pressed.down then
        self:_fullDimension('h')
    else
      self:_nextStep('h', false, function (cell, nextSize)
        cell.y = 0
        cell.h = self.GRID.h / nextSize
      end)
    end
  end, function ()
    self._pressed.up = false
  end)

  -- ---- Fullscreen cycling ----

  hs.hotkey.bind(mapping.fullscreen[1], mapping.fullscreen[2], function ()
    self:_nextFullScreenStep()
  end)

  -- ---- Next screen ----

  if mapping.nextscreen then
    hs.hotkey.bind(mapping.nextscreen[1], mapping.nextscreen[2], function ()
      self:_moveNextScreenStep()
    end)
  end

  -- ---- Middle / Center ----

  if mapping.middle then
    hs.hotkey.bind(mapping.middle[1], mapping.middle[2], function ()
      -- Center the window at its current size
      if hs.window.focusedWindow() then
        local win = hs.window.frontmostWindow()
        local screen = win:screen()
        local cell = hs.grid.get(win, screen)
        cell.x = (G.w - cell.w) / 2
        cell.y = (G.h - cell.h) / 2
        hs.grid.set(win, cell, screen)
      end
    end)
  end

  -- ==================================================================
  -- ULTRA-WIDE COLUMN ZONES (NEW)
  -- Grid is 24 wide. Thirds = 8 columns each. Halves = 12 each.
  -- Quarters = 6 each. Sixths = 4 each.
  -- ==================================================================

  -- Column 1: left third (cycles: 1/3 -> 1/4 -> 1/6)
  if mapping.col1 then
    hs.hotkey.bind(mapping.col1[1], mapping.col1[2], function ()
      self:_cycleZones({
        {0, 0, 8, G.h},     -- left 1/3
        {0, 0, 6, G.h},     -- left 1/4
        {0, 0, 4, G.h},     -- left 1/6
      })
    end)
  end

  -- Column 2: center third (cycles: center 1/3 -> center 1/4)
  if mapping.col2 then
    hs.hotkey.bind(mapping.col2[1], mapping.col2[2], function ()
      self:_cycleZones({
        {8, 0, 8, G.h},     -- center 1/3
        {9, 0, 6, G.h},     -- center 1/4
      })
    end)
  end

  -- Column 3: right third (cycles: 1/3 -> 1/4 -> 1/6)
  if mapping.col3 then
    hs.hotkey.bind(mapping.col3[1], mapping.col3[2], function ()
      self:_cycleZones({
        {16, 0, 8, G.h},    -- right 1/3
        {18, 0, 6, G.h},    -- right 1/4
        {20, 0, 4, G.h},    -- right 1/6
      })
    end)
  end

  -- Left 2/3 (cycles: 2/3 -> 3/4)
  if mapping.twothirdL then
    hs.hotkey.bind(mapping.twothirdL[1], mapping.twothirdL[2], function ()
      self:_cycleZones({
        {0, 0, 16, G.h},    -- left 2/3
        {0, 0, 18, G.h},    -- left 3/4
      })
    end)
  end

  -- Right 2/3 (cycles: 2/3 -> 3/4)
  if mapping.twothirdR then
    hs.hotkey.bind(mapping.twothirdR[1], mapping.twothirdR[2], function ()
      self:_cycleZones({
        {8, 0, 16, G.h},    -- right 2/3
        {6, 0, 18, G.h},    -- right 3/4
      })
    end)
  end

  -- Center column cycling (center 1/3 -> center 1/2 -> center 2/3)
  if mapping.centerCycle then
    hs.hotkey.bind(mapping.centerCycle[1], mapping.centerCycle[2], function ()
      self:_cycleZones({
        {8, 0, 8, G.h},     -- center 1/3
        {6, 0, 12, G.h},    -- center 1/2
        {4, 0, 16, G.h},    -- center 2/3
      })
    end)
  end

  -- ==================================================================
  -- QUADRANT ZONES (NEW) - corners of the screen
  -- Each quadrant is 1/2 width x 1/2 height
  -- Cycles: half-by-half -> third-by-half
  -- ==================================================================

  if mapping.topleft then
    hs.hotkey.bind(mapping.topleft[1], mapping.topleft[2], function ()
      self:_cycleZones({
        {0, 0, 12, 12},     -- top-left (half x half)
        {0, 0, 8, 12},      -- top-left (third x half)
        {0, 0, 6, 12},      -- top-left (quarter x half)
      })
    end)
  end

  if mapping.topright then
    hs.hotkey.bind(mapping.topright[1], mapping.topright[2], function ()
      self:_cycleZones({
        {12, 0, 12, 12},    -- top-right (half x half)
        {16, 0, 8, 12},     -- top-right (third x half)
        {18, 0, 6, 12},     -- top-right (quarter x half)
      })
    end)
  end

  if mapping.bottomleft then
    hs.hotkey.bind(mapping.bottomleft[1], mapping.bottomleft[2], function ()
      self:_cycleZones({
        {0, 12, 12, 12},    -- bottom-left (half x half)
        {0, 12, 8, 12},     -- bottom-left (third x half)
        {0, 12, 6, 12},     -- bottom-left (quarter x half)
      })
    end)
  end

  if mapping.bottomright then
    hs.hotkey.bind(mapping.bottomright[1], mapping.bottomright[2], function ()
      self:_cycleZones({
        {12, 12, 12, 12},   -- bottom-right (half x half)
        {16, 12, 8, 12},    -- bottom-right (third x half)
        {18, 12, 6, 12},    -- bottom-right (quarter x half)
      })
    end)
  end

  -- ==================================================================
  -- TOP/BOTTOM THIRD COLUMNS (NEW)
  -- Splits each third column into top and bottom halves
  -- Useful for stacking 6 windows (2 rows x 3 columns)
  -- ==================================================================

  if mapping.topthirdL then
    hs.hotkey.bind(mapping.topthirdL[1], mapping.topthirdL[2], function ()
      self:_cycleZones({
        {0, 0, 8, 12},      -- top-left 1/3
        {0, 0, 6, 12},      -- top-left 1/4
      })
    end)
  end

  if mapping.topthirdM then
    hs.hotkey.bind(mapping.topthirdM[1], mapping.topthirdM[2], function ()
      self:_cycleZones({
        {8, 0, 8, 12},      -- top-center 1/3
        {6, 0, 12, 12},     -- top-center 1/2
      })
    end)
  end

  if mapping.topthirdR then
    hs.hotkey.bind(mapping.topthirdR[1], mapping.topthirdR[2], function ()
      self:_cycleZones({
        {16, 0, 8, 12},     -- top-right 1/3
        {18, 0, 6, 12},     -- top-right 1/4
      })
    end)
  end

  if mapping.botthirdL then
    hs.hotkey.bind(mapping.botthirdL[1], mapping.botthirdL[2], function ()
      self:_cycleZones({
        {0, 12, 8, 12},     -- bottom-left 1/3
        {0, 12, 6, 12},     -- bottom-left 1/4
      })
    end)
  end

  if mapping.botthirdM then
    hs.hotkey.bind(mapping.botthirdM[1], mapping.botthirdM[2], function ()
      self:_cycleZones({
        {8, 12, 8, 12},     -- bottom-center 1/3
        {6, 12, 12, 12},    -- bottom-center 1/2
      })
    end)
  end

  if mapping.botthirdR then
    hs.hotkey.bind(mapping.botthirdR[1], mapping.botthirdR[2], function ()
      self:_cycleZones({
        {16, 12, 8, 12},    -- bottom-right 1/3
        {18, 12, 6, 12},    -- bottom-right 1/4
      })
    end)
  end

  -- ---- Nudge left/right (slide window keeping its size) ----

  if mapping.nudgeLeft then
    hs.hotkey.bind(mapping.nudgeLeft[1], mapping.nudgeLeft[2], function ()
      self:_nudge('left')
    end)
  end

  if mapping.nudgeRight then
    hs.hotkey.bind(mapping.nudgeRight[1], mapping.nudgeRight[2], function ()
      self:_nudge('right')
    end)
  end

end

function obj:init()
  print("Initializing Miro's Windows Manager (Ultra-Wide Edition)")
  hs.grid.setGrid(obj.GRID.w .. 'x' .. obj.GRID.h)
  hs.grid.MARGINX = 0
  hs.grid.MARGINY = 0
end

return obj
