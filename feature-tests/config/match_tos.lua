--[[
  Feature test for matching IP ToS/DSCP or IPv6 traffic class field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_TOS = FeatureConfig.enum.TOS.mod

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_tos=" .. Feature.pkt.TOS .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_tos=" .. new_TOS .. ", actions=DROP")
  end

Feature.config{
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.TOS = new_TOS
  end
  
  
return feature