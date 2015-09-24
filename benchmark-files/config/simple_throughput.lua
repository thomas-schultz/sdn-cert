--[[
  Test:   direct pass through with two ports
  Result: throughput and latency
]]

require "benchmark_config"
  
local bench = {} 

bench.require = "match_inport"
 
bench.loadGen = "moongen"
bench.files   = "load-latency.lua"
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
bench.ofArgs  = "$link=1 $link=2"

bench.flowEntries = function(flowData, inPort, outPort)
    table.insert(flowData.flows, "in_port=" .. inPort .. ", actions=output:" .. outPort)
  end

return bench