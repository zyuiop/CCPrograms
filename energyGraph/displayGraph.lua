-- Sensor client

function min_max(array)
  if #array == 0 then return nil, nil end

  local min = array[1]
  local max = array[1]

  for _, num in pairs(array) do
    if num > max then max = num end
    if num < min then min = num end
  end

  return min, max
end

-- Display a graph on the screen
-- Param: graph, an array of values
-- Param: mode, "expand" (TODO) or "last" (default)
function display_graph(graph, mode)
  -- Determine minimum and maximum values
  local min, max = min_max(graph)
  if min == max then
    min = min - 1
    max = max + 1
  end
  local width, height = term.getSize()


  local unit_factor = 1
  local unit = ''
  if max > 1000 then 
    unit_factor = 1000
    unit = 'K' 
  end
  
  if max > 1000000 then 
    unit_factor = 1000000
    unit = 'M' 
  end

  -- Draw axis
  local left_axis_space = math.floor(math.log10(max / unit_factor))

  term.setCursorPos(1, 1)
  term.write((max / unit_factor) .. unit)

  term.setCursorPos(1, height)
  term.write((min / unit_factor) .. unit)

  paintutils.drawLine(left_axis_space + 2, 1, left_axis_space + 2, height, colors.white)


  local remaining_width = (width - left_axis_space - 1)

  -- We have a value in [min, max]
  -- min has position HEIGHT, max has position 1
  -- percentage: (x - min) / (max - min)
  -- position: percentage * height
  -- so in the end, height * (x - min) / (max - min)
  local fact = height / (max - min)
  local position = function (y)
    return height - math.floor((y - min) * fact)
  end

  if mode == nil or mode == "last" then
    x = width
    i = #graph
    while x > left_axis_space and i > 0 do
      v = graph[i]
      paintutils.drawPixel(x, position(v), colors.blue)
      x = x - 1
      i = i - 1
    end
  end

  -- EXPAND mode not implemented.
end

return { display_graph = display_graph }