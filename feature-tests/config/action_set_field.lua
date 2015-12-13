--[[
  Feature test for set arbitrary fields in the header
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.wol
Feature.pkt.PROTO = Feature.enum.PROTO.undef

local new_SRC_MAC = "aa:aa:aa:aa:aa:aa"
local new_SRC_IP4 = "10.0.2.1"
--local new_SRC_PORT = 4321

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "priority=1, dl_type=" .. Feature.enum.ETH_TYPE.wol .. ", actions=set_field:" .. new_SRC_MAC .. "->dl_src,ALL")
    table.insert(flowData.flows, "priority=2, ip, actions=set_field:" .. new_SRC_IP4 .. "->nw_src,ALL")
    --table.insert(flowData.flows, "priority=3, ip, udp, actions=set_field:" .. Feature.new_SRC_PORT .. "->tp_src,ALL")
  end

Feature.config{
  txIterations = 2,
  desiredCtr = 2,
} 

Feature.modifyPkt = function(pkt, iteration)
    if (iteration == 1) then
      Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip4
    elseif (iteration == 2) then
      Feature.pkt.PROTO = Feature.enum.ETH_TYPE.udp
    end
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_mac == new_SRC_MAC) end,
    function(pkt) return (pkt.src_ip == new_SRC_IP4) end,
    --function(pkt) return (pkt.src_port == new_SRC_PORT) end,
  }
  
Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1],batch/2,threshold) and Feature.eval(ctrs[2],batch/2,threshold))
  end

return feature