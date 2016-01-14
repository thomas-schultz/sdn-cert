--[[
  Feature test for all out-ports packets
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2 $link=3"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  ctrType = "all",
}

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=ALL")
  end

return Feature