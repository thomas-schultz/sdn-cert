---------------
-- CSV Tools --
---------------

csv = {}

function csv.transpose(data)
  local res = {} 
  for i = 1, #data[1] do
      res[i] = {}
      for j = 1, #data do
          res[i][j] = data[j][i]
      end
  end
  return res
end

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

csv.getStats = function(data, crop)
  local crop = crop or 0
  local data = csv.transpose(data)
  local stats = {}
  for i,row in pairs(data) do
    if (i>crop and i<(#data-crop)) then
      stats[i-crop] = statistic.getFullStats(row)
    end
  end
  return stats
end
