--[[
  Feature test for matching of L2 MAC-addresses
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

Feature.config{
  new_SRC_MAC = "aa:00:00:00:00:a2",
  new_DST_MAC = "aa:aa:aa:aa:aa:aa",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("dl_src=%s, dl_dst=%s, actions=output:%s", Feature.pkt.SRC_MAC, Feature.pkt.DST_MAC, outPort))
    table.insert(flowData.flows, string.format("dl_src=%s, dl_dst=%s, actions=DROP", conf.new_SRC_MAC, conf.new_DST_MAC))
  end
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_MAC = conf.new_SRC_MAC 
    pkt.DST_MAC = conf.new_DST_MAC
  end
  
  
return Feature