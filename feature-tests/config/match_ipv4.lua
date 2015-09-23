--[[
  Feature test for matching of IPv4 src and dst field
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_SRC_IP4 = "10.0.2.1"
feature.new_DST_IP4 = "10.0.2.2"

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_src=" .. feature.pkt.SRC_IP4 .. ", nw_dst=" .. feature.pkt.DST_IP4 .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_src=" .. feature.new_SRC_IP4 .. ", nw_dst=" .. feature.new_DST_IP4 .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.SRC_IP4 = feature.new_SRC_IP4 
    feature.pkt.DST_IP4 = feature.new_DST_IP4
  end
  
  
return feature