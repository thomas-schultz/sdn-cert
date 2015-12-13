--[[
  Feature test for modifying Ethernet source and destination address
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow10"
Feature.state   = "recommended"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link*"
    
Feature.pkt = Feature.getDefaultPkt()

local new_SRC_MAC = "aa:00:00:00:00:a2"
local new_DST_MAC = "aa:aa:aa:aa:aa:aa" 

Feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=mod_dl_src=" .. new_SRC_MAC .. ", mod_dl_dst=" .. new_DST_MAC .. ", ALL")
  end

Feature.config{
} 
 
FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_mac == new_SRC_MAC and pkt.dst_mac == new_DST_MAC) end
  }

return feature