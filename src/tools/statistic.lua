-------------------------
-- Statistic functions --
-------------------------

Statistic = {}


function Statistic.readHistogram(hist, resolution)
  local occurrence = {}
  local times = {}
  local min, max
  if (not hist) then return occurrence end
  local dataFile = io.open(hist, "r")
  if (not dataFile) then return occurrence end
  while (true) do
    local line = dataFile:read()
    if (line == nil) then break end
    local item = string.split(line, ",")
    local time, value = Float.tonumber(item[1]), item[2]
    occurrence[time] = value
    table.insert(times, time)
    min = math.min(min or time, time)
    max = math.max(max or time, time)
  end
  io.close(dataFile)
  table.sort(times)
  local collapsedOccurrence = {}
  local collapsedTimes = {}
  local stepSize = (max - min) / (resolution or 2048)
  local step = min
  local time, count = min, occurrence[min]
  local avgTime = 0
  for _,t in pairs(times) do
    local v = occurrence[t]
    if (t <= step + stepSize) then
      time = time + v*t
      count = count + v
    else
      local avgTime = (time / count) / 1000 -- change ns to µs
      collapsedOccurrence[avgTime] = count
      table.insert(collapsedTimes, avgTime)
      step = t
      time = v*t
      count = v
    end
  end
  collapsedOccurrence[avgTime] = count
  local result = {}
  table.sort(collapsedTimes)
  for _,t in pairs(collapsedTimes) do 
    local line = string.replace(""..t, ",", ".") .. "," ..collapsedOccurrence[t]
    table.insert(result, line)
  end
  return result
end


function Statistic.sortList(list)
  local sortedList = { }
  for _, value in pairs(list) do
    table.insert(sortedList, Float.tonumber(value))
  end
  table.sort(sortedList)
  return sortedList
end

function Statistic.getPercentile(list, p, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  return list[math.ceil(#list * p / 100)]
end

function Statistic.getQuantiles(list, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  return list[math.ceil(#list * 1/4)], list[math.ceil(#list * 3/4)]
end

function Statistic.getMedian(list, isSorted)
  local isSorted = isSorted or false
  if type(list) ~= 'table' then return list end
  if (not isSorted) then
    list = Statistic.sortList(list)
  end
  if #list %2 == 0 then return (list[#list/2] + list[#list/2+1]) / 2 end
  return list[math.ceil(#list/2)]
end

function Statistic.getAvarage(list)
  if type(list) ~= 'table' then return list end
  local sum, num = 0, 0
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      sum = sum + value
      num = num + 1
    end
  end
  return sum/num
end

function Statistic.getMinMax(list)
  if type(list) ~= 'table' then return list end
  local min, max
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      min = math.min(min or value, value)
      max = math.max(max or value, value)
    end
  end
  return min, max
end

function Statistic.getFullStats(list, lowP, highP)
  local lowP = lowP or 25
  local highP = highP or 75
  if type(list) ~= 'table' then return list end
  local stats = {num = 0, sum = 0}
  local sortedList = {}
  for _,value in pairs(list) do
    local value = Float.tonumber(value)
    if (value) then
      stats.num = stats.num + 1
      stats.sum = stats.sum + value
      stats.min = math.min(stats.min or value, value)
      stats.max = math.max(stats.max or value, value)
      table.insert(sortedList, value)
    end
  end
  table.sort(sortedList)
  stats.avg = stats.sum / stats.num 
  stats.median = Statistic.getMedian(sortedList, true)
  stats.lowP = Statistic.getPercentile(sortedList, lowP, true)
  stats.highP = Statistic.getPercentile(sortedList, highP, true)
  return stats
end