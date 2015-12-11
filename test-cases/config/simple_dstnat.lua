--[[
  Test:   direct pass through with two ports, replacing the destination IP field
  Result: throughput and latency
]]

require "benchmark_config"
  
local bench = {} 

bench.require = "match_ethertype modify_ipv4"
 
bench.loadGen = "moongen"
bench.files   = "load-latency.lua"
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
bench.ofArgs  = "$link=1 $link=2"

bench.settings = {
  SRC_DST = "128.0.0.1"
}

bench.flowEntries = function(flowData, inPort, outPort)
    local pkt = bench.settings
    local flow = string.format("ip,in_port=%d, actions=mod_nw_dst=%s,output:%d", inPort, pkt.SRC_DST, outPort)
    table.insert(flowData.flows, flow)
  end
  
bench.metric = "load-latency"

return bench