--[[
  Feature test for group type SELECT
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFLow11"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

Feature.flowEntries = function(flowData)
    table.insert(flowData.groups, "group_id=1, type=select, bucket=mod_nw_src=" .. new_SRC_IP4 .. ",ALL bucket=mod_nw_dst=" .. new_DST_IP4 .. ",ALL")
    table.insert(flowData.flows, "actions=group:1")
  end

Feature.config{
}

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP4 and pkt.dst_ip ~= new_DST_IP4) end,
    function(pkt) return (pkt.src_ip ~= new_SRC_IP4 and pkt.dst_ip == new_DST_IP4) end,
  }
  
Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1],batch,threshold) and not Feature.eval(ctrs[2],batch,threshold)) or
           (not Feature.eval(ctrs[1],batch,threshold) and Feature.eval(ctrs[2],batch,threshold))
  end

return feature