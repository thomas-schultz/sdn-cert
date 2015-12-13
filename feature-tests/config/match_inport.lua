--[[
  Feature test for matching of OpenFlow ingress port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
Feature.ofArgs  = "$link*"
  	
Feature.pkt = Feature.getDefaultPkt()

Feature.flowEntries = function(flowData, ...)
    local action = "ALL"
    for i,v in pairs({...}) do
      table.insert(flowData.flows, "in_port=" .. v .. ", actions=" .. action)
      action = "DROP"
    end
  end

Feature.config{
  firstRxDev = 1,
  txIterations = 2,
  learnFrames = 0,
} 
  
Feature.modifyPkt = function(pkt, iteration)
    Feature.set("txDev", 2)
  end


return feature