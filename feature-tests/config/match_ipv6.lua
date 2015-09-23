--[[
  Feature test for matching of IPv6 src and dst field
]]

feature = require "feature_config"

feature.require = "OpenFlow12"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001"
feature.new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip6, ipv6_src=" .. feature.pkt.SRC_IP6 .. ", ipv6_dst=" .. feature.pkt.DST_IP6 .. ", actions=ALL")
    table.insert(flowData.flows, "ip6, ipv6_src=" .. feature.new_SRC_IP6 .. ", ipv6_dst=" .. feature.new_DST_IP6 .. ", actions=DROP")
  end

feature.config{
  ip6 = true,
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.SRC_IP6 = feature.new_SRC_IP6 
    feature.pkt.DST_IP6 = feature.new_DST_IP6
  end
  
  
return feature