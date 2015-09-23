--[[
  Feature test for matching Ethertype
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
  	
feature.pkt = feature.defaultPkt

feature.new_ETH_TYPE = feature.enum.ETH_TYPE.wol

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_type=" .. feature.pkt.ETH_TYPE4 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. feature.pkt.ETH_TYPE6 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. feature.new_ETH_TYPE .. ", actions=DROP")
  end

feature.config{
} 
	
feature.modifyPkt = function(pkt, iteration)
    pkt.ETH_TYPE = feature.new_ETH_TYPE
    pkt.PROTO = feature.enum.PROTO.undef
  end


return feature