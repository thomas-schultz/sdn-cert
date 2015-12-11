-------------------------
-- Statistic functions --
-------------------------

statistic = {}


function statistic.sortList(list)
  local sortedList = { }
  for _, value in pairs(list) do
    table.insert(sortedList, float.tonumber(value))
  end
  table.sort(sortedList)
  return sortedList
end

function statistic.getPercentile(list, p, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = statistic.sortList(list)
  end
  return list[math.ceil(#list * p / 100)]
end

function statistic.getQuantiles(list, isSorted)
  local isSorted = isSorted or false
  if (not isSorted) then
    list = statistic.sortList(list)
  end
  return list[math.ceil(#list * 1/4)], list[math.ceil(#list * 3/4)]
end

function statistic.getMedian(list, isSorted)
  local isSorted = isSorted or false
  if type(list) ~= 'table' then return list end
  if (not isSorted) then
    list = statistic.sortList(list)
  end
  if #list %2 == 0 then return (list[#list/2] + list[#list/2+1]) / 2 end
  return list[math.ceil(#list/2)]
end

function statistic.getAvarage(list)
  if type(list) ~= 'table' then return list end
  local sum, num = 0, 0
  for _,value in pairs(list) do
    local value = float.tonumber(value)
    if (value) then
      sum = sum + value
      num = num + 1
    end
  end
  return sum/num
end

function statistic.getMinMax(list)
  if type(list) ~= 'table' then return list end
  local min, max
  for _,value in pairs(list) do
    local value = float.tonumber(value)
    if (value) then
      min = math.min(min or value,value)
      max = math.max(max or value,value)
    end
  end
  return min, max
end

function statistic.getFullStats(list, pl, ph)
  local pl = pl or 9
  local ph = ph or 91
  if type(list) ~= 'table' then return list end
  local stats = {num = 0, sum = 0}
  local sortedList = {}
  for _,value in pairs(list) do
    local value = float.tonumber(value)
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
  stats.median = statistic.getMedian(sortedList, true)
  stats.lowP = statistic.getPercentile(sortedList, pl, true)
  stats.highP = statistic.getPercentile(sortedList, ph, true)
  return stats
end