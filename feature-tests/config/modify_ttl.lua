--[[
  Feature test for modifying IP TTL or IPv6 hop limit value
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_TTL = Feature.enum.TTL.min

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_ttl=" .. new_TTL .. ", ALL")
    table.insert(flowData.flows, "ipv6, actions=mod_nw_ttl=" .. new_TTL .. ", ALL")
  end

Feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.ttl == new_TTL) end
  }

return feature