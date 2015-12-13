--[[
  Test:   direct pass through with two ports depending on number of table entries
  Result: throughput and latency
]]

require "benchmark_config"
  
local Test = {} 

Test.require = "match_ipv4, modify_ipv4"
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
Test.ofArgs  = "$numIP $link=2"
   
Test.settings = {
  BASE_IP = "10.0.0.0",
}

Test.flowEntries = function(flowData, numIP, outPort)
  local pkt = Test.settings
  local ip = BenchmarkConfig.IP.parseIP(pkt.BASE_IP)
  for i=1,tonumber(numIP) do
    local currentMatch = BenchmarkConfig.IP.getIP(ip)
    BenchmarkConfig.IP.incAndWrap(ip)
    local currentTarget = BenchmarkConfig.IP.getIP(ip)
    table.insert(flowData.flows, "ip, nw_dst=" .. currentMatch ..", actions=mod_nw_dst=" .. currentTarget .. ",output:" .. outPort)
  end
end

Test.metric = "load-latency"

return Test