--[[
  Feature test for normal hybrid L2/L3 behavior
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, "priority=1, actions=NORMAL")
    table.insert(flowData.flows, "priority=0, actions=DROP")
  end

feature.config{
}

return feature