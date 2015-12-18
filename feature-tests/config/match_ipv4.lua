--[[
  Feature test for matching of IPv4 src and dst field
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
  txIterations = 2,
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
})
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, nw_src=%s, nw_dst=%s, actions=DROP", Feature.pkt.SRC_IP4, Feature.pkt.DST_IP4))
    table.insert(flowData.flows, string.format("ip, nw_src=%s, nw_dst=%s, actions=output:%s", conf.new_SRC_IP4, conf.new_DST_IP4, outPort))
  end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_IP4 = conf.new_SRC_IP4 
    pkt.DST_IP4 = conf.new_DST_IP4
  end
  
return Feature