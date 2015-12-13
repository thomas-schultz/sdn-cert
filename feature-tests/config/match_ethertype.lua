--[[
  Feature test for matching Ethertype
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
  	
Feature.pkt = Feature.getDefaultPkt()

local new_ETH_TYPE = Feature.enum.ETH_TYPE.wol

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "dl_type=" .. Feature.enum.ETH_TYPE.ip4 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. Feature.enum.ETH_TYPE.ip6 .. ", actions=ALL")
    table.insert(flowData.flows, "dl_type=" .. new_ETH_TYPE .. ", actions=DROP")
  end

Feature.config{
  txIterations = 2,
} 
	
Feature.modifyPkt = function(pkt, iteration)
    Feature.pkt.ETH_TYPE = new_ETH_TYPE
    Feature.pkt.PROTO = Feature.enum.PROTO.undef
  end


return feature