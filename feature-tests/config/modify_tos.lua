--[[
  Feature test for modifying IP ToS/DSCP or IPv6 traffic class field
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_TOS = feature.enum.TOS.mod

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, actions=mod_nw_tos=" .. feature.new_TOS .. ", ALL")
    table.insert(flowData.flows, "ipv6, actions=mod_nw_tos=" .. feature.new_TOS .. ", ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.tos == feature.new_TOS) end
  }

return feature