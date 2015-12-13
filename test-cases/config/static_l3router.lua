--[[
  Test:   static L3-router with TTL decrement
  Result: throughput and latency
]]

require "benchmark_config"
  
local Test = {} 

Test.require = "match_ethertype, modify_l2addr, action_dec_ttl"
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate 1 $pktSize"
Test.ofArgs  = "$link=1 $link=2"

Test.settings = {
  SRC_MAC = "55:44:33:22:11:00",
  DST_MAC = "00:11:22:33:44:55",
}

Test.flowEntries = function(flowData, inPort, outPort)
    local pkt = Test.settings
    local flow = string.format("ip,in_port=%d, actions=mod_dl_src=%s,mod_dl_dst=%s,dec_ttl, output:%d", inPort, pkt.SRC_MAC, pkt.DST_MAC, outPort)
    table.insert(flowData.flows, flow)
  end
  
Test.metric = "load-latency"

return Test