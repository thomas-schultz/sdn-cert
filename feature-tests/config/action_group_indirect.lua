--[[
  Feature test for group type INDIRECT
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFLow11"
Feature.state   = "required"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

Feature.flowEntries = function(flowData)
    table.insert(flowData.groups, "group_id=1, type=indirect, bucket=mod_nw_src=" .. new_SRC_IP4 .. ",mod_nw_dst=" .. new_DST_IP4 .. ",ALL")
    table.insert(flowData.flows, "actions=group:1")
  end

Feature.config{
}

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP4 and pkt.dst_ip == new_DST_IP4) end,
  }

return Feature