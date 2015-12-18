--[[
  Feature test for modifying Ethernet source and destination address
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()

Feature.settings = {
  new_SRC_MAC = "aa:00:00:00:00:a2",
  new_DST_MAC = "aa:aa:aa:aa:aa:aa",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("actions=mod_dl_src=%s, mod_dl_dst=%s, output:%s", conf.new_SRC_MAC, conf.new_DST_MAC, outPort))
  end
 
Feature.pktClassifier = {
    function(pkt) return (pkt.src_mac == conf.new_SRC_MAC and pkt.dst_mac == conf.new_DST_MAC) end
  }

return Feature