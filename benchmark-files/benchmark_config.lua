--Benchmark config file

BenchmarkConfig = {}

local function parseIP(addr)
  local oct1,oct2,oct3,oct4 = addr:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
  return {oct1, oct2, oct3, oct4}
end

local function incAndWrap(ip)
  ip[4] = ip[4] + 1
  for oct=4,1,-1 do
    if (ip[oct] > 255) then
      ip[oct] = 0
      ip[oct-1] = ip[oct-1] + 1
    else break end
  end
  if (ip[0]) then
    ip[0] = nil
    ip[4] = 0
  end
end

local function getIP(ip)
  local addr = tostring(ip[1])
  for i=2,4 do addr = addr .. "." .. tostring(ip[i]) end
  return addr
end

BenchmarkConfig.simple_throughput = function(flowData, inPort, outPort)
  table.insert(flowData.flows, "in_port=" .. inPort .. ", actions=output:" .. outPort)
end

BenchmarkConfig.table_size = function(flowData, baseIP, numIP, outPort)
  local ip = parseIP(baseIP)
  for i=1,tonumber(numIP) do
    local currentMatch = getIP(ip)
    incAndWrap(ip)
    local currentTarget = getIP(ip)
    table.insert(flowData.flows, "ip, nw_dst=" .. currentMatch ..", actions=mod_nw_dst=" .. currentTarget .. ",output:" .. outPort)
  end
end

return BenchmarkConfig