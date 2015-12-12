--[[
  Feature test for decreasing the IP TTL or IPv6 hop limit value
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "recommended"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=dec_ttl, ALL")
    table.insert(flowData.flows, "ipv6, actions=dec_ttl, ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.ttl == feature.pkt.TTL - 1) end,
  }

return feature