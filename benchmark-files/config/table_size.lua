--[[
  Test:   direct pass through with two ports depending on number of table entries
  Result: throughput and latency
]]

require "benchmark_config"
  
local bench = {} 

bench.require = "match_ipv4, modify_ipv4"
 
bench.loadGen = "moongen"
bench.files   = "load-latency.lua"
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
bench.ofArgs  = "$baseIP $link=1 link=2"
   
bench.config{
  baseIP = "10.0.0.0",
}

bench.flowEntries = function(flowData, baseIP, numIP, outPort)
  local ip = parseIP(baseIP)
  for i=1,tonumber(numIP) do
    local currentMatch = getIP(ip)
    incAndWrap(ip)
    local currentTarget = getIP(ip)
    table.insert(flowData.flows, "ip, nw_dst=" .. currentMatch ..", actions=mod_nw_dst=" .. currentTarget .. ",output:" .. outPort)
  end
end

return bench