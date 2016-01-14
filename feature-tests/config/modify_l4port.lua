--[[
  Feature test for modifying the UDP or TCP or SCTP source and destination port
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

Feature.settings = {
  new_SRC_PORT = 4321,
  new_DST_PORT = 8765,
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ip, udp, actions=mod_tp_src=%s, mod_tp_dst=%s, output:%s", conf.new_SRC_PORT, conf.new_DST_PORT, outPort))
    table.insert(flowData.flows, string.format("ip, tcp, actions=mod_tp_src=%s, mod_tp_dst=%s, output:%s", conf.new_SRC_PORT, conf.new_DST_PORT, outPort))
  end

Feature.pktClassifier = {
    function(pkt) return (pkt.src_port == conf.new_SRC_PORT and pkt.dst_port == conf.new_DST_PORT) end
  }

return Feature