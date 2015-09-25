--[[
  Benchmark template
]]

-- imports all needed function and default values, do not remove!
require "benchmark_config"
  
local bench = {} 

-- required features
bench.require = "match_inport"

-- load generating tool
bench.loadGen = "moongen"
-- list of files to copy to the load generator host, use space as separator or specify as table
bench.files   = "load-latency.lua"
-- argument list for the load generator, use space as separator or specify as table
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
-- argument list which will be mapped and than passed to the flowEntries function, can be omitted
bench.ofArgs  = "$link=1 $link=2"

-- creating of the flow entries in flowData = { flows, groups, meters }
bench.flowEntries = function(flowData, inPort, outPort)
    table.insert(flowData.flows, "in_port=" .. inPort .. ", actions=output:" .. outPort)
  end

return bench