--[[
  Feature test for matching IP TTL or IPv6 hop limit value
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_TTL = FeatureConfig.enum.TTL.min

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, nw_ttl=" .. feature.pkt.TTL .. ", actions=ALL")
    table.insert(flowData.flows, "ip, nw_ttl=" .. feature.new_TTL .. ", actions=DROP")
  end

feature.config{
} 
  
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.TTL = feature.new_TTL
  end
  
  
return feature