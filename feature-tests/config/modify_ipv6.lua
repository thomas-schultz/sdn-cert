--[[
  Feature test for modifying the IPv6 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip6

local new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001"
local new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002"

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ipv6, actions=set_field:" .. new_SRC_IP6 .. "->ipv6_src, set_field:" .. new_DST_IP6 .. "->ipv6_dst, ALL")
  end

Feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP6 and pkt.dst_ip == new_DST_IP6) end,
  }

return Feature