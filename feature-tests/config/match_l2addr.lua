--[[
  Feature test for matching of L2 MAC-addresses
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_MAC = "aa:00:00:00:00:a2"
local new_DST_MAC = "aa:aa:aa:aa:aa:aa"

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_src=" .. Feature.pkt.SRC_MAC .. ", dl_dst=" .. Feature.pkt.DST_MAC .. ", actions=ALL")
    table.insert(flowData.flows, "dl_src=" .. new_SRC_MAC .. ", dl_dst=" .. new_DST_MAC .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.SRC_MAC = new_SRC_MAC 
    Feature.pkt.DST_MAC = new_DST_MAC
  end
  
  
return Feature