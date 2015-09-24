--[[
  Feature test for duplicating packets
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
feature.ofArgs  = "$link=2"
    
feature.pkt = feature.getDefaultPkt()

feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, "actions=output:" .. tostring(outPort) .. "," .. tostring(outPort))
  end

feature.config{
  desiredCtr = 2,
}

return feature