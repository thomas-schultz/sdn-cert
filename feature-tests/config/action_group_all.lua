--[[
  Feature test for group type ALL
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFLow11"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  desiredCtr = 2,
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.groups, string.format("group_id=1, type=all, bucket=mod_nw_src=%s,output:%s, bucket=mod_nw_dst=%s,output:%s", conf.new_SRC_IP4, outPort, conf.new_DST_IP4, outPort))
    table.insert(flowData.flows, "actions=group:1")
  end

Feature.pktClassifier = {
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP4 and pkt.dst_ip ~= conf.new_DST_IP4) end,
    function(pkt) return (pkt.src_ip ~= conf.new_SRC_IP4 and pkt.dst_ip == conf.new_DST_IP4) end,
  }

Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1],batch/2,threshold) and Feature.eval(ctrs[2],batch/2,threshold))
  end

return Feature