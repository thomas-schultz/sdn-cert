--[[
  Feature test for modifying IP ToS/DSCP or IPv6 traffic class field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_TOS = Feature.enum.TOS.mod

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_tos=" .. new_TOS .. ", ALL")
    table.insert(flowData.flows, "ipv6, actions=mod_nw_tos=" .. new_TOS .. ", ALL")
  end

Feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.tos == new_TOS) end
  }

return feature