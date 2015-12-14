--[[
  Test-case template file
]]

-- imports all needed function and default values, do not remove!
require "testcase_config"
  
local Test = {} 

-- required features
Test.require = "match_inport"

-- load generating tool
Test.loadGen = "moongen"
-- list of files to copy to the load generator host, use space as separator or specify as table
Test.files   = "load-latency.lua"
-- argument list for the load generator, use space as separator or specify as table
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
-- argument list which will be mapped and than passed to the flowEntries function, can be omitted
Test.ofArgs  = "$link=1 $link=2"

-- specific values for use configuration, only used inside this file
Test.settings = {
  variable = "value",
  number = 42,
}

-- creating of the flow entries in flowData = { flows, groups, meters }
Test.flowEntries = function(flowData, inPort, outPort)
    table.insert(flowData.flows, string.format("in_port=%d, actions=output:%d", inPort, outPort))
  end

Test.metric = "load-latency"
  
return Test