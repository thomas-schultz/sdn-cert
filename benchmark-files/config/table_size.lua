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
bench.ofArgs  = "$numIP $link=2"
   
bench.settings = {
  BASE_IP = "10.0.0.0",
}

bench.flowEntries = function(flowData, numIP, outPort)
  local ip = BenchmarkConfig.IP.parseIP(bench.settings.BASE_IP)
  for i=1,tonumber(numIP) do
    local currentMatch = BenchmarkConfig.IP.getIP(ip)
    BenchmarkConfig.IP.incAndWrap(ip)
    local currentTarget = BenchmarkConfig.IP.getIP(ip)
    table.insert(flowData.flows, "ip, nw_dst=" .. currentMatch ..", actions=mod_nw_dst=" .. currentTarget .. ",output:" .. outPort)
  end
end

bench.metric = "load-latency"

return bench