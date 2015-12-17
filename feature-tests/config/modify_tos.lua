--[[
  Feature test for modifying IP ToS/DSCP or IPv6 traffic class field
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
  new_TOS = Feature.enum.TOS.mod,
} 
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, actions=mod_nw_tos=%s, output:%s", conf.new_TOS, outPort))
    table.insert(flowData.flows, string.format("ipv6, actions=mod_nw_tos=%s, output:%s", conf.new_TOS, outPort))
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.tos == conf.new_TOS) end
  }

return Feature