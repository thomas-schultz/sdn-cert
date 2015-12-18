--[[
  Feature test for matching the UDP source and destination port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.config(Feature, {
  xIterations = 2,
  new_SRC_PORT = 4321,
  new_DST_PORT = 8765,
})
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, udp, tp_src=%s, tp_dst=%s, actions=DROP", Feature.pkt.SRC_PORT, Feature.pkt.DST_PORT))
    table.insert(flowData.flows, string.format("ip, udp, tp_src=%s, tp_dst=%s, actions=output:%s", conf.new_SRC_PORT, conf.new_DST_PORT, outPort))
  end


  
Feature.modifyPkt = function(pkt, iteration)
    pkt.SRC_PORT = conf.new_SRC_PORT
    pkt.DST_PORT = conf.new_DST_PORT
  end
  
  
return setmetatable({}, Feature)