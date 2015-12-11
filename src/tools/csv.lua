---------------
-- CSV Tools --
---------------

CSV = {}

function CSV.print(data)
  for i,row in pairs(data) do
    for j,value in pairs(row) do
      io.write(value .. ",\t")
    end
    io.write("\n")
  end
end

function CSV.transpose(data)
  local res = {}
  for i = 1, #data[1] do
    res[i] = {}
    for j = 1, #data do
        res[i][j] = data[j][i]
    end
  end
  return res
end

CSV.parseCSV = function(file, separator)
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

CSV.parseAndCropCSV = function(file, crop, header, separator)
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

CSV.getStats = function(data, crop, lowP, highP)
  local crop = crop or 0
  local stats = {}
  for i,row in pairs(data) do
    if (i>crop and i<(#data-crop)) then
      stats[i-crop] = Statistic.getFullStats(row)
    end
  end
  return stats
end
