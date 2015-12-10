--[[
  Feature test for group type SELECT
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFLow11"
feature.state   = "required"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

feature.flowEntries = function(flowData)
    table.insert(flowData.groups, "group_id=1, type=select, bucket=mod_nw_src=" .. new_SRC_IP4 .. ",ALL bucket=mod_nw_dst=" .. new_DST_IP4 .. ",ALL")
    table.insert(flowData.flows, "actions=group:1")
  end

feature.config{
}

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP4 and pkt.dst_ip ~= new_DST_IP4) end,
    function(pkt) return (pkt.src_ip ~= new_SRC_IP4 and pkt.dst_ip == new_DST_IP4) end,
  }
  
feature.evalCounters = function(ctrs, batch, threshold)
    return (feature.eval(ctrs[1],batch,threshold) and not feature.eval(ctrs[2],batch,threshold)) or
           (not feature.eval(ctrs[1],batch,threshold) and feature.eval(ctrs[2],batch,threshold))
  end

return feature