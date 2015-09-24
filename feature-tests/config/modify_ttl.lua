--[[
  Feature test for modifying IP TTL or IPv6 hop limit value
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow11"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

feature.new_TTL = feature.enum.TTL.min

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_ttl=" .. feature.new_TTL .. ", ALL")
    table.insert(flowData.flows, "ipv6, actions=mod_nw_ttl=" .. feature.new_TTL .. ", ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.ttl == feature.new_TTL) end
  }

return feature