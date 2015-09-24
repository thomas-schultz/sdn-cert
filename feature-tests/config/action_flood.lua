--[[
  Feature test for flooding packets
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=FLOOD")
  end

feature.config{
  ctrType = "all",
}

return feature