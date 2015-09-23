--[[
  Feature test for set arbitrary fields in the header
]]

feature = require "feature_config"

feature.require = "OpenFlow11"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt
feature.pkt.ETH_TYPE4 = feature.enum.ETH_TYPE.wol
feature.pkt.PROTO = feature.enum.PROTO.undef

fetaure.new_SRC_MAC = "aa:aa:aa:aa:aa:aa"
fetaure.new_SRC_IP4 = "10.0.2.1"
fetaure.new_SRC_PORT = 4321

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "priority=1, dl_type=" .. feature.enum.ETH_TYPE.wol .. ", actions=set_field:" .. fetaure.new_SRC_MAC .. "->dl_src, ALL")
    table.insert(flowData.flows, "priority=2, ip, actions=set_field:" .. fetaure.new_SRC_IP4 .. "->nw_src, ALL")
    table.insert(flowData.flows, "priority=3, ip, udp, actions=set_field:" .. fetaure.new_SRC_PORT .. "->tp_src, ALL")
  end

feature.config{
  txIterations = 3,
  desiredCtr = 3,
} 

feature.modifyPkt = function(pkt, iteration)
    if (iteration == 1) then
      feature.pkt.ETH_TYPE4 = feature.enum.ETH_TYPE.ip4
    elseif (iteration == 2) then
      feature.pkt.PROTO = feature.enum.ETH_TYPE.udp
    end
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_mac == fetaure.new_SRC_MAC) end,
    function(pkt) return (pkt.src_ip == fetaure.new_SRC_IP4) end,
    function(pkt) return (pkt.src_port == fetaure.new_SRC_PORT) end,
  }
  
feature.evalCounters = function(ctrs, batch, threshold)
    return (feature.eval(ctrs[1],batch,threshold) and feature.eval(ctrs[2],batch,threshold) and feature.eval(ctrs[3],batch,threshold))
  end

return feature