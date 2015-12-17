--[[
  Feature test for decreasing the IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.config{
}

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, actions=dec_ttl, action=output:%s", outPort))
    table.insert(flowData.flows, string.format("ipv6, actions=dec_ttl, action=output:%s", outPort))
  end

Feature.pktClassifier = {
    function(pkt) return (pkt.ttl == Feature.pkt.TTL - 1) end,
  }

return Feature