--[[
  Feature test for decreasing the IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=dec_ttl, ALL")
    table.insert(flowData.flows, "ipv6, actions=dec_ttl, ALL")
  end

Feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.ttl == Feature.pkt.TTL - 1) end,
  }

return Feature