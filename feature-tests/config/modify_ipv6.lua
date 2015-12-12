--[[
  Feature test for modifying the IPv6 src and dst field
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow12"
feature.state   = "recommended"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()
feature.pkt.ETH_TYPE = feature.enum.ETH_TYPE.ip6

local new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001"
local new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ipv6, actions=set_field:" .. new_SRC_IP6 .. "->ipv6_src, set_field:" .. new_DST_IP6 .. "->ipv6_dst, ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP6 and pkt.dst_ip == new_DST_IP6) end,
  }

return feature