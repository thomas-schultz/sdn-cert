--[[
  Feature test for matching IP ToS/DSCP or IPv6 traffic class field
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_TOS = FeatureConfig.enum.TOS.mod

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_tos=" .. feature.pkt.TOS .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_tos=" .. feature.new_TOS .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.TOS = feature.new_TOS
  end
  
  
return feature