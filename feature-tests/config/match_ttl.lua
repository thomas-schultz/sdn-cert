--[[
  Feature test for matching IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.new_TTL = FeatureConfig.enum.TTL.min

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_ttl=" .. Feature.pkt.TTL .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_ttl=" .. Feature.new_TTL .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.TTL = Feature.new_TTL
  end
  
  
return Feature