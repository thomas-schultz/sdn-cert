--[[
  Feature test for modifying Ethernet source and destination address
]]

require "feature_config"

local feature = FeatureConfig.new()

feature.require = "OpenFlow10"
feature.state   = "recommended"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.getDefaultPkt()

local new_SRC_MAC = "aa:00:00:00:00:a2"
local new_DST_MAC = "aa:aa:aa:aa:aa:aa" 

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=mod_dl_src=" .. new_SRC_MAC .. ", mod_dl_dst=" .. new_DST_MAC .. ", ALL")
  end

feature.config{
} 
 
FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_mac == new_SRC_MAC and pkt.dst_mac == new_DST_MAC) end
  }

return feature