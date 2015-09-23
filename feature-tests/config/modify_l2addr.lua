--[[
  Feature test for modifying Ethernet source and destination address
]]

feature = require "feature_config"

feature.require = "OpenFlow10"
feature.state   = "optional"
  
feature.loadGen = "moongen"
feature.files   = "feature_test.lua"
feature.lgArgs  = "$file=1 $name $link*"
    
feature.pkt = feature.defaultPkt

feature.new_SRC_MAC = "aa:00:00:00:00:a2"
feature.new_DST_MAC = "aa:aa:aa:aa:aa:aa" 

feature.flowEntries = function(flowData)
    table.insert(flowData.flows, "actions=mod_dl_src=" .. feature.new_SRC_MAC .. ", mod_dl_dst=" .. feature.new_DST_MAC .. ", ALL")
  end

feature.config{
} 
 
FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_mac == feature.new_SRC_MAC and pkt.dst_mac == feature.new_DST_MAC) end
  }

return feature