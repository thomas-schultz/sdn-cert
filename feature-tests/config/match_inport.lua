--[[
  Feature test for matching of OpenFlow ingress port
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
feature.ofArgs  = "$link*"
  	
feature.pkt = feature.defaultPkt

feature.flowEntries = function(flowData, ...)
    local action = "ALL"
    for i,v in pairs({...}) do
      table.insert(flowData.flows, "in_port=" .. v .. ", actions=" .. action)
      action = "DROP"
    end
  end

feature.config{
  firstRxDev = 1,
  txIterations = 2,
  learnFrames = 0,
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.set("txDev", 2)
  end


return feature