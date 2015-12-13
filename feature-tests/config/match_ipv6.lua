--[[
  Feature test for matching of IPv6 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip6

local new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001"
local new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002"

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip6, ipv6_src=" .. Feature.pkt.SRC_IP6 .. ", ipv6_dst=" .. Feature.pkt.DST_IP6 .. ", actions=ALL")
    table.insert(flowData.flows, "ip6, ipv6_src=" .. new_SRC_IP6 .. ", ipv6_dst=" .. new_DST_IP6 .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.SRC_IP6 = new_SRC_IP6 
    Feature.pkt.DST_IP6 = new_DST_IP6
  end
  
  
return feature