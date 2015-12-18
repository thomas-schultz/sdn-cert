--[[
  Feature test for duplicating packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  desiredCtr = 2,
}

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("actions=output:%s,%s", outPort, outPort))
  end

return Feature