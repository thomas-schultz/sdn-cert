--[[
  Feature test for matching of L2 MAC-addresses
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_SRC_MAC = "aa:00:00:00:00:a2"
local new_DST_MAC = "aa:aa:aa:aa:aa:aa"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_src=" .. feature.pkt.SRC_MAC .. ", dl_dst=" .. feature.pkt.DST_MAC .. ", actions=ALL")
    table.insert(flowData.flows, "dl_src=" .. new_SRC_MAC .. ", dl_dst=" .. new_DST_MAC .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.SRC_MAC = new_SRC_MAC 
    feature.pkt.DST_MAC = new_DST_MAC
  end
  
  
return feature