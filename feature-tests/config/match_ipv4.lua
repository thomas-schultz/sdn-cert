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
Feature.ofArgs  = "$link=1 $link=2"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

Feature.flowEntries = function(flowData, inPort, outPort)
    table.insert(flowData.flows, string.format("ip, nw_src=%s, nw_dst=%s, actions=output:%s", Feature.pkt.SRC_IP4, Feature.pkt.DST_IP4, outPort))
    table.insert(flowData.flows, string.format("ip, nw_src=%s, nw_dst=%s, actions=DROP", new_SRC_IP4, new_DST_IP4))
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.SRC_IP4 = new_SRC_IP4 
    Feature.pkt.DST_IP4 = new_DST_IP4
  end
  
  
return Feature