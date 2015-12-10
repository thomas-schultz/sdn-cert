--[[
  Feature test for matching the UDP source and destination port
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_SRC_PORT = 4321
local new_DST_PORT = 8765

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, udp, tp_src=" .. feature.pkt.SRC_PORT .. ", tp_dst=" .. feature.pkt.DST_PORT .. ", actions=ALL")
    table.insert(flowData.flows, "ip, udp, tp_src=" .. new_SRC_PORT .. ", tp_dst=" .. new_DST_PORT .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.SRC_PORT = new_SRC_PORT
    feature.pkt.DST_PORT = new_DST_PORT
  end
  
  
return feature