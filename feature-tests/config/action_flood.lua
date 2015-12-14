--[[
  Feature test for flooding packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=FLOOD")
  end

Feature.config{
  ctrType = "all",
}

return Feature