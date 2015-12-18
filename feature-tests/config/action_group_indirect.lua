--[[
  Feature test for group type INDIRECT
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
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.groups, string.format("group_id=1, type=indirect, bucket=mod_nw_src=%s,mod_nw_dst=%s,output:%s", conf.new_SRC_IP4, conf.new_DST_IP4, outPort))
    table.insert(flowData.flows, "actions=group:1")
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP4 and pkt.dst_ip == conf.new_DST_IP4) end,
  }

return Feature