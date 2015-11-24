---------------
-- CSV Tools --
---------------

csv = {}

csv.parseCsv = function(file, separator)
  local separator = separator or ","
  local t = {}
  local data = io.open(file, "r")
  if (not data) then return t end
  while (true) do
    local line = data:read()
    if (line == nil) then break end
    table.insert(t, string.split(line, separator))
  end
  io.close(data)
  return t
end

csv.parseAndCropCsv = function(file, crop, header, separator)
  local separator = separator or ","
  local t = {}
  local data = io.open(file, "r")
  if (not data) then return t end
  local crop = crop or 0
  local lines = 0
  while (true) do
    local line = data:read()
    if (line == nil) then break end
    if ( (lines == 0 and header)) then
      header = false
      table.insert(t, string.split(line, separator))
    else
      lines = lines + 1
      if (lines > crop) then
        table.insert(t, string.split(line, separator))
      end
    end
  end
  local len = #t
  for i=0,crop do t[len-i] = nil end
  io.close(data)
  return t
end

csv.getStats = function(data, clipBorder)
  clipBorder = clipBorder or false
  local stats = {}
  if (not data[1]) then return stats end
  for j,_ in pairs(data[1]) do
    stats[j] = {}
    stats[j].num = 0
    stats[j].sum = 0
  end
  for i,row in pairs(data) do
    if (not clipBorder or (i>1) and (i<#data)) then
      for j,col in pairs(row) do
        local value = float.tonumber(col)
        if (value) then        
          stats[j].num = stats[j].num + 1
          stats[j].sum = stats[j].sum + value
          stats[j].min = math.min(stats[j].min or value,value)
          stats[j].max = math.max(stats[j].max or value,value)
          stats[j].avg = stats[j].sum / stats[j].num 
        end
      end
    end
  end
  return stats
end
