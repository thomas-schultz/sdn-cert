--[[
  Feature test for matching of IPv6 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip6

Feature.config(Feature, {
  txIterations  = 2,
  new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001",
  new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip6, ipv6_src=%s, ipv6_dst=%s, actions=DROP", Feature.pkt.SRC_IP6, Feature.pkt.DST_IP6))
    table.insert(flowData.flows, string.format("ip6, ipv6_src=%s, ipv6_dst=%s, actions=output:%s", conf.new_SRC_IP6, conf.new_DST_IP6, outPort))
  end

Feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_IP6 = conf.new_SRC_IP6 
    pkt.DST_IP6 = conf.new_DST_IP6
  end
  
  
return Feature