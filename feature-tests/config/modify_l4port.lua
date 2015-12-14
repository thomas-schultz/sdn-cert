--[[
  Feature test for modifying the UDP or TCP or SCTP source and destination port
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_PORT = 4321
local new_DST_PORT = 8765

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, udp, actions=mod_tp_src=" .. new_SRC_PORT .. ", mod_tp_dst=" .. new_DST_PORT .. ", ALL")
    table.insert(flowData.flows, "ip, tcp, actions=mod_tp_src=" .. new_SRC_PORT .. ", mod_tp_dst=" .. new_DST_PORT .. ", ALL")
  end

Feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_port == new_SRC_PORT and pkt.dst_port == new_DST_PORT) end
  }

return Feature