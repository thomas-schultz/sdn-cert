--[[
  Feature test for modifying the IPv4 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_src=" .. new_SRC_IP4 .. ",mod_nw_dst=" .. new_DST_IP4 .. ", ALL")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_IP4 = new_SRC_IP4
    pkt.DST_IP4 = new_DST_IP4
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP4 and pkt.dst_ip == new_DST_IP4) end,
  }

return Feature