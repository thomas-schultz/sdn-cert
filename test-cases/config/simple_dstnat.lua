--[[
  Test:   direct pass through with two ports, replacing the destination IP field
  Result: throughput and latency
]]

require "benchmark_config"
  
local Test = {} 

Test.require = "match_ethertype modify_ipv4"
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
Test.ofArgs  = "$link=1 $link=2"

Test.settings = {
  SRC_DST = "128.0.0.1"
}

Test.flowEntries = function(flowData, inPort, outPort)
    local pkt = Test.settings
    local flow = string.format("ip,in_port=%d, actions=mod_nw_dst=%s,output:%d", inPort, pkt.SRC_DST, outPort)
    table.insert(flowData.flows, flow)
  end
  
Test.metric = "load-latency"

return Test