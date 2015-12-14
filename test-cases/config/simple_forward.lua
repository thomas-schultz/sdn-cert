--[[
  Test:   direct pass through with two ports
  Result: throughput and latency
]]

require "testcase_config"
  
local Test = {} 

Test.require = "match_inport"
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
Test.ofArgs  = "$link=1 $link=2"

Test.flowEntries = function(flowData, inPort, outPort)
    local flow = string.format("in_port=%d, actions=output:%d", inPort, outPort)
    table.insert(flowData.flows, flow)
  end
  
Test.metric = "load-latency"

return Test