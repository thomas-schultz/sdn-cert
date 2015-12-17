--[[
  Feature test for set arbitrary fields in the header
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow11"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.wol
Feature.pkt.PROTO = Feature.enum.PROTO.undef

Feature.config{
  txIterations = 2,
  desiredCtr = 2,
  new_SRC_MAC = "aa:aa:aa:aa:aa:aa",
  new_SRC_IP4 = "10.0.2.1",
  --local new_SRC_PORT = 4321,
} 
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("priority=1, dl_type=%s, actions=set_field:%s->dl_src, output:%s", tostring(Feature.enum.ETH_TYPE.wol), conf.new_SRC_MAC, outPort))
    table.insert(flowData.flows, string.format("priority=2, ip, actions=set_field:%s->nw_src, output:%s", tostring(Feature.enum.ETH_TYPE.wol), conf.new_SRC_IP4, outPort))
    --table.insert(flowData.flows, string.format("priority=3, ip, udp, actions=set_field:%s->tp_src, output:%s", Feature.enum.ETH_TYPE.wol, conf.new_SRC_PORT, outPort))
  end

Feature.modifyPkt = function(pkt, iteration)
    if (iteration == 1) then
      pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip4
    elseif (iteration == 2) then
      pkt.PROTO = Feature.enum.ETH_TYPE.udp
    end
  end

Feature.pktClassifier = {
    function(pkt) return (pkt.src_mac == conf.new_SRC_MAC) end,
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP4) end,
    --function(pkt) return (pkt.src_port == conf.new_SRC_PORT) end,
  }
  
Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1],batch/2,threshold) and Feature.eval(ctrs[2],batch/2,threshold))
  end

return Feature