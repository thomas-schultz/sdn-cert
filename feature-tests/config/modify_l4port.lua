--[[
  Feature test for modifying the UDP or TCP or SCTP source and destination port
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "recommended"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_SRC_PORT = 4321
local new_DST_PORT = 8765

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "ip, udp, actions=mod_tp_src=" .. new_SRC_PORT .. ", mod_tp_dst=" .. new_DST_PORT .. ", ALL")
    table.insert(flowData.flows, "ip, tcp, actions=mod_tp_src=" .. new_SRC_PORT .. ", mod_tp_dst=" .. new_DST_PORT .. ", ALL")
  end

feature.config{
} 

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_port == new_SRC_PORT and pkt.dst_port == new_DST_PORT) end
  }

return feature