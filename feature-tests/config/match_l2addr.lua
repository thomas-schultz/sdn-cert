--[[
  Feature test for matching of L2 MAC-addresses
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_SRC_MAC = "aa:00:00:00:00:a2"
feature.new_DST_MAC = "aa:aa:aa:aa:aa:aa"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_src=" .. feature.pkt.SRC_MAC .. ", dl_dst=" .. feature.pkt.DST_MAC .. ", actions=ALL")
    table.insert(flowData.flows, "dl_src=" .. feature.new_SRC_MAC .. ", dl_dst=" .. feature.new_DST_MAC .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.SRC_MAC = feature.new_SRC_MAC 
    feature.pkt.DST_MAC = feature.new_DST_MAC
  end
  
  
return feature