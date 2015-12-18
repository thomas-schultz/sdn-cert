--[[
  Feature test for matching IP ToS/DSCP or IPv6 traffic class field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.config(Feature, {
  xIterations = 2,
  new_TOS = FeatureConfig.enum.TOS.mod,
})
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, nw_tos=%s, actions=DROP", Feature.pkt.TOS))
    table.insert(flowData.flows, string.format("ip, nw_tos=%s, actions=output:%s", conf.new_TOS, outPort))  
  end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.TOS = conf.new_TOS
  end
  
  
return setmetatable({}, Feature)