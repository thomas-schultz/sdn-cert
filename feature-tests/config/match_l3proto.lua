--[[
  Feature test for matching the protocol in the IP Header 
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_PROTO = feature.enum.PROTO.tcp

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_proto=" .. feature.pkt.PROTO .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_proto=" .. new_PROTO .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.PROTO = feature.new_PROTO
  end
  
  
return feature