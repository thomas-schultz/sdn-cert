--[[
  Feature test for matching of IPv4 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_src=" .. Feature.pkt.SRC_IP4 .. ", nw_dst=" .. Feature.pkt.DST_IP4 .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_src=" .. new_SRC_IP4 .. ", nw_dst=" .. new_DST_IP4 .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.SRC_IP4 = new_SRC_IP4 
    Feature.pkt.DST_IP4 = new_DST_IP4
  end
  
  
return feature