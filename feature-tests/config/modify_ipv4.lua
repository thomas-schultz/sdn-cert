--[[
  Feature test for modifying the IPv4 src and dst field
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

feature.new_SRC_IP4 = "10.0.2.1"
feature.new_DST_IP4 = "10.0.2.2"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_src=" .. feature.new_SRC_IP4 .. ",mod_nw_dst=" .. feature.new_DST_IP4 .. ", ALL")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_IP4 = feature.new_SRC_IP4
    pkt.DST_IP4 = feature.new_DST_IP4
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == feature.new_SRC_IP4 and pkt.dst_ip == feature.new_DST_IP4) end,
  }

return feature