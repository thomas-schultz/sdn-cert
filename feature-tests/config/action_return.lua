--[[
  Feature test for returning packets on the ingress port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=output:IN_PORT")
  end

Feature.config{
  firstRxDev = 1,
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.devId == Feature.settings.txDev) end,
  }

return feature