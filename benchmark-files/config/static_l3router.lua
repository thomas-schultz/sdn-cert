--[[
  Test:   static L3-router with TTL decrement
  Result: throughput and latency
]]

require "benchmark_config"
  
local bench = {} 

bench.require = "match_ethertype, modify_l2addr, action_dec_ttl"
 
bench.loadGen = "moongen"
bench.files   = "load-latency.lua"
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate 1 $pktSize"
bench.ofArgs  = "$link=1 $link=2"

bench.settings = {
  SRC_MAC = "55:44:33:22:11:00",
  DST_MAC = "00:11:22:33:44:55",
}

bench.flowEntries = function(flowData, inPort, outPort)
    local pkt = bench.settings
    local flow = string.format("ip,in_port=%d, actions=mod_dl_src=%s,mod_dl_dst=%s,dec_ttl, output:%d", inPort, pkt.SRC_MAC, pkt.DST_MAC, outPort)
    table.insert(flowData.flows, flow)
  end
  
bench.metric = "load-latency"

return bench