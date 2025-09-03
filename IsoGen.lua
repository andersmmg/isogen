-- Version 0.1.1
-- Created by: Andersmmg
-- Description: Create isometric shapes easily (Aseprite extension)
-- Github: github.com/andersmmg/isogen
-- License: MIT

local dlg = Dialog("IsoGen")

local maxSize = {
  x = math.floor(app.activeSprite.width / 4),
  y = math.floor(app.activeSprite.width / 4),
  z = math.floor(app.activeSprite.height / 2),
}

local Shapes = {
  CUBE = "Cube",
  STAIR = "Stair",
  CIRCLE = "Circle",
}

local c = app.fgColor;
local colors = {
  stroke = Color { h = 0, s = 0, v = 0, a = 255 },
  top = app.fgColor,
  left = Color { h = c.hsvHue, s = c.hsvSaturation + 0.3, v = c.hsvValue - 0.1, a = 255 },
  right = Color { h = c.hsvHue, s = c.hsvSaturation + 0.3, v = c.hsvValue - 0.2, a = 255 },
  highlight = Color { h = c.hsvHue, s = c.hsvSaturation - 0.2, v = c.hsvValue + 0.2, a = 255 },
  shine = Color { h = c.hsvHue, s = 0.1, v = 1.0, a = 255 },
}

local centerX = math.floor(app.activeSprite.width / 2)
local centerY = math.floor(app.activeSprite.height / 2)

local selected_shape = Shapes.CUBE
local leftMiddle = true
local createdLayers = {}
local offset = 0
local data = {}
local shineEnabled = true
local highlightEnabled = true
local highlightOnTop = false
local fillEnabled = true
local cornerSize = 2

local function setColorsFromCurrent()
  c = app.fgColor;
  colors = {
    stroke = Color { h = 0, s = 0, v = 0, a = 255 },
    top = app.fgColor,
    left = Color { h = c.hsvHue, s = c.hsvSaturation + 0.3, v = c.hsvValue - 0.1, a = 255 },
    right = Color { h = c.hsvHue, s = c.hsvSaturation + 0.3, v = c.hsvValue - 0.2, a = 255 },
    highlight = Color { h = c.hsvHue, s = c.hsvSaturation - 0.2, v = c.hsvValue + 0.2, a = 255 },
    shine = Color { h = c.hsvHue, s = 0.1, v = 1.0, a = 255 },
  }

  dlg:modify { id = "topColor", color = colors.top }
  dlg:modify { id = "shadeColor", color = colors.left }
  dlg:modify { id = "frontColor", color = colors.right }
  dlg:modify { id = "highlightColor", color = colors.highlight }
end

local function drawStraightLine(x, y, len, color, direction)
  local drawFuncs = {
    vertical = function(i) app.activeImage:putPixel(x, y + i, color) end,
    horizontal = function(i) app.activeImage:putPixel(x + i, y, color) end
  }

  local drawFunc = drawFuncs[direction]

  for i = 1, len do
    drawFunc(i)
  end
end

local function fillSquare(x, y, color)
  local fillPoint = Point { x, y }

  app.useTool {
    tool = "paint_bucket",
    color = color,
    points = { fillPoint },
    cel = app.activeCel,
    layer = app.activeLayer,
    frame = app.activeFrame,
  }
end

local function colorCube(x, y, z)
  fillSquare(centerX, centerY - 1, data.topColor) -- Top
  -- TODO: maybe fallback for 3px height?
  --   currently doesn't fill anything as gap isn't continuous
  if data.zSize > 2 then
    fillSquare((centerX - y * 2 - 1) + 1, (centerY - y) + 3, data.frontColor) -- Left
    fillSquare(centerX + x * 2 - 1, centerY - x + 3, data.shadeColor)         -- Right
  end
end

local function isoLine(x, y, len, color, direction)
  local step = direction == "upRight" and 1 or -1
  for i = 0, len do
    local baseX = x + i * 2 * step
    app.activeImage:putPixel(baseX, y - i, color)
    app.activeImage:putPixel(baseX + step, y - i, color)
  end
end

local function drawCube(x, y, z, color)
  offset = leftMiddle and -1 or 0

  local leftShift = cornerSize > 2 and -1 or 0
  local rightShift = cornerSize > 3 and 1 or 0

  --- Highlight
  if not highlightOnTop then
    drawStraightLine(centerX + offset, centerY, z, highlightEnabled and data.highlightColor or color, "vertical")   -- Middle
    isoLine(centerX - 1 + rightShift, centerY + 1, x, highlightEnabled and data.highlightColor or color, "upRight") -- Middle Right
    isoLine(centerX + leftShift, centerY + 1, y, highlightEnabled and data.highlightColor or color, "upLeft")       -- Middle Left
  end

  -- Strokes
  isoLine(centerX - y * 2 - 1 + leftShift, centerY - y, x, color, "upRight")           -- Top Left
  isoLine(centerX + x * 2 + rightShift, centerY - x, y, color, "upLeft")               -- Top Right
  isoLine(centerX + leftShift, centerY + z, y, color, "upLeft")                        -- Bottom Left
  isoLine(centerX - 1 + rightShift, centerY + z, x, color, "upRight")                  -- Bottom Right

  drawStraightLine(centerX - y * 2 - 1 + leftShift, centerY - y, z, color, "vertical") -- Left
  drawStraightLine(centerX + x * 2 + rightShift, centerY - x, z, color, "vertical")    -- Right

  --- Highlight if on top
  if highlightOnTop then
    drawStraightLine(centerX + offset, centerY, z, highlightEnabled and data.highlightColor or color, "vertical")   -- Middle
    isoLine(centerX - 1 + rightShift, centerY + 1, x, highlightEnabled and data.highlightColor or color, "upRight") -- Middle Right
    isoLine(centerX + leftShift, centerY + 1, y, highlightEnabled and data.highlightColor or color, "upLeft")       -- Middle Left
  end

  -- Shine
  if shineEnabled then
    app.activeImage:putPixel(centerX + offset, centerY + 1, data.shineColor)
  end
end

local function newLayer(name)
  local sprite = app.activeSprite
  local layer = sprite:newLayer()
  layer.name = name
  sprite:newCel(layer, 1)
  table.insert(createdLayers, layer)
  return layer
end

local function undoLastLayerCreation()
  if #createdLayers > 0 then
    local lastLayer = table.remove(createdLayers)
    sprite:deleteLayer(lastLayer)
  end
end

dlg:combobox { id = "shapeType", label="Shape:", option = "Cube", options = { Shapes.CUBE }, onchange = function()
      selected_shape = dlg.data.shapeType
    end }

dlg:separator { text = "Dimensions" }
    :slider { id = "ySize", label = "Left:", min = 1, max = maxSize.y, value = 8 }
    :slider { id = "xSize", label = "Right:", min = 1, max = maxSize.x, value = 8 }
    :slider { id = "zSize", label = "Height:", min = 0, max = maxSize.z, value = 16 }

dlg:separator { text = "Fill Colors:" }
    :check {
      id = "fillEnabled",
      text = "Enabled",
      selected = fillEnabled,
      onclick = function()
        fillEnabled = not fillEnabled
        dlg:modify { id = "topColor", visible = fillEnabled }
        dlg:modify { id = "shadeColor", visible = fillEnabled }
        dlg:modify { id = "frontColor", visible = fillEnabled }
      end
    }
    :color { id = "topColor", label = "Top:", color = colors.top }
    :color { id = "shadeColor", label = "Left:", color = colors.left }
    :color { id = "frontColor", label = "Right:", color = colors.right }

dlg:separator { text = "Stroke Colors:" }
    :color {
      id = "strokeColor",
      label = "Stroke:",
      color = colors.stroke
    }
    :check {
      id = "highlightEnabled",
      label = "Highlight:",
      text = "Enabled",
      selected = highlightEnabled,
      onclick = function()
        highlightEnabled = not highlightEnabled
        dlg:modify { id = "highlightColor", visible = highlightEnabled }
        dlg:modify { id = "highlightOnTop", visible = highlightEnabled }
      end
    }
    :color {
      id = "highlightColor",
      color = colors.highlight,
    }
    :check {
      id = "highlightOnTop",
      text = "Draw highlights on top",
      selected = highlightOnTop,
      onclick = function()
        highlightOnTop = not highlightOnTop
      end
    }

dlg:separator { text = "Shine" }
    :check {
      id = "shineEnabled",
      text = "Enabled",
      selected = shineEnabled,
      onclick = function()
        shineEnabled = not shineEnabled
        dlg:modify { id = "shineColor", visible = shineEnabled }
      end
    }
    :color {
      id = "shineColor",
      color = colors.shine,
      visible = shineEnabled
    }

dlg:separator { text = "Options" }
    :radio {
      id = "left",
      label = "Middle Line: ",
      text = "Left",
      selected = leftMiddle,
      onclick = function() leftMiddle = true end
    }
    :radio {
      id = "right",
      text = "Right",
      selected = not leftMiddle,
      onclick = function() leftMiddle = false end
    }
    :combobox {
      id = "cornerSize",
      label = "Corner Width:",
      options = { "2px", "3px", "4px" },
      option = "2px",
      onchange = function()
        local value = dlg.data.cornerSize
        if value == "2px" then
          cornerSize = 2
        elseif value == "3px" then
          cornerSize = 3
          dlg:modify { id = "left", selected = true }
          leftMiddle = true
        elseif value == "4px" then
          cornerSize = 4
        end
        dlg:modify { id = "left", visible = cornerSize ~= 3 }
        dlg:modify { id = "right", visible = cornerSize ~= 3 }
      end
    }

dlg:button {
  id = "setColorsFromCurrent",
  text = "Get Colors",
  onclick = function()
    setColorsFromCurrent()
    app.refresh()
  end
}

-- dlg:button {
--   id = "undo",
--   text = "Undo",
--   onclick = function()
--     undoLastLayerCreation()
--     app.refresh()
--   end,
--   enabled = function()
--     return #createdLayers > 0
--   end
-- }

dlg:button {
  id = "submit",
  text = "Add Shape",
  onclick = function()
    data = dlg.data
    app.transaction(function()
      if selected_shape == Shapes.CUBE then
        newLayer("Cube(" .. data.xSize .. " " .. data.ySize .. " " .. data.zSize .. ")")
        drawCube(data.xSize - 1, data.ySize - 1, data.zSize + 1, data.strokeColor)
        if fillEnabled then
          colorCube(data.xSize - 1, data.ySize - 1)
        end
      elseif selected_shape == Shapes.STAIR then
        print("Stair not implemented yet.")
      elseif selected_shape == Shapes.CIRCLE then
        print("Circle not implemented yet.")
      end
    end)
    app.refresh()
  end
}

function showDialog()
  dlg:show { wait = false }
end

return {
  showDialog = showDialog,
}
