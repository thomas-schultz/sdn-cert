--[[
  Feature test for returning packets on the ingress port
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=output:IN_PORT")
  end

feature.config{
  firstRxDev = 1,
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.devId == feature.settings.txDev) end,
  }

return feature