--[[
  Feature test for duplicating packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, "actions=output:" .. tostring(outPort) .. "," .. tostring(outPort))
  end

Feature.config{
  desiredCtr = 2,
}

return feature