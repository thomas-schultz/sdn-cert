--[[
  Feature test for matching the protocol in the IP Header 
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

Feature.settings = {
  xIterations = 2,
  new_PROTO = Feature.enum.PROTO.tcp,
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, nw_proto=%s, actions=DROP", Feature.pkt.PROTO))
    table.insert(flowData.flows, string.format("ip, nw_proto=%s, actions=output:%s", conf.new_PROTO, outPort))
  end
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.PROTO = Feature.new_PROTO
  end
  
return Feature