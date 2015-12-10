--[[
  Feature test for modifying IP ToS/DSCP or IPv6 traffic class field
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_TOS = feature.enum.TOS.mod

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_tos=" .. new_TOS .. ", ALL")
    table.insert(flowData.flows, "ipv6, actions=mod_nw_tos=" .. new_TOS .. ", ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.tos == new_TOS) end
  }

return feature