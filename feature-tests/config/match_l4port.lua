--[[
  Feature test for matching the UDP source and destination port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_PORT = 4321
local new_DST_PORT = 8765

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, udp, tp_src=" .. Feature.pkt.SRC_PORT .. ", tp_dst=" .. Feature.pkt.DST_PORT .. ", actions=ALL")
    table.insert(flowData.flows, "ip, udp, tp_src=" .. new_SRC_PORT .. ", tp_dst=" .. new_DST_PORT .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.SRC_PORT = new_SRC_PORT
    Feature.pkt.DST_PORT = new_DST_PORT
  end
  
  
return feature