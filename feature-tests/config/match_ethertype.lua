--[[
  Feature test for matching Ethertype
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
  	
feature.pkt = feature.getDefaultPkt()

feature.new_ETH_TYPE = feature.enum.ETH_TYPE.wol

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_type=" .. feature.enum.ETH_TYPE.ip4 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. feature.enum.ETH_TYPE.ip6 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. feature.new_ETH_TYPE .. ", actions=DROP")
  end

feature.config{
  txIterations = 2,
} 
	
feature.modifyPkt = function(pkt, iteration)
    feature.pkt.ETH_TYPE = feature.new_ETH_TYPE
    feature.pkt.PROTO = feature.enum.PROTO.undef
  end


return feature