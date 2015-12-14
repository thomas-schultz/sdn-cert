--[[
  Feature test for matching the protocol in the IP Header 
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_PROTO = Feature.enum.PROTO.tcp

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_proto=" .. Feature.pkt.PROTO .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_proto=" .. new_PROTO .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.PROTO = Feature.new_PROTO
  end
  
  
return Feature