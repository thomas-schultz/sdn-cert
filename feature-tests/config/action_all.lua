--[[
  Feature test for all out-ports packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.config{
  ctrType = "all",
}

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=ALL")
  end

return Feature