--[[
  Feature template
]]

-- imports all needed function and default values, do not remove!
require "feature_config"

-- creates new Feature from feature_config file, do not remove!
local feature = FeatureConfig.new()

-- required OpenFlow Version
feature.require = "OpenFlow10"
-- what does the specification say about it
feature.state   = "required"
  
-- load generating tool
feature.loadGen = "moongen"
-- list of files to copy to the load generator host, use space as separator or specify as table
feature.files   = "feature_test.lua"
-- argument list for the load generator, use space as separator or specify as table
feature.lgArgs  = "$file=1 $name $links"
-- argument list which will be mapped and than passed to the flowEntries function, can be omitted
feature.ofArgs  = "$link*"

-- allowing for specific settings, default values can be overwritten, may be omitted
feature.config{
  iterations = 1
} 

-- creating of the flow entries in flowData = { flows, groups, meters }
feature.flowEntries = function(flowData, ...)
    table.insert(flowData.flows, "actions=DROP")
    table.insert(flowData.groups, "group_id=1,type=all,bucket=DROP")
    table.insert(flowData.meters, "meter=1,kbps,burst,band=type=drop,rate=1000")
  end
  
-- sepcifies the packet, either use the default, or define your own
feature.pkt  = getPkt(FeatureConfig.defaultPkt)

-- local variable for modifying packet, can be chosen freely
local new_ETH_TYPE = feature.enum.ETH_TYPE.wol
local new_SRC_IP4 = "10.0.2.1"
local new_DST_IP4 = "10.0.2.2"

-- modify function, called after every iteration, ignored if only one pass is used, may be omitted  
feature.modifyPkt = function(iteration)
    feature.pkt.ETH_TYPE = new_ETH_TYPE
    feature.pkt.PROTO = feature.enum.PROTO.undef
  end

-- packet classifier functions, every entry evaluates to a boolean value, then the packet
-- get classified with the index of this function in the table, may be omitted 
feature.pktClassifier = {
    function(pkt) return (pkt.src_ip == new_SRC_IP4 and pkt.dst_ip ~= new_DST_IP4) end,
    function(pkt) return (pkt.src_ip ~= new_SRC_IP4 and pkt.dst_ip == new_DST_IP4) end,
  }

-- function of how the classified packet counters should be compared, returns test result, may be omitted
feature.evalCounters = function(ctrs, batch, threshold)
    return (feature.eval(ctrs[1],batch,threshold) or feature.eval(ctrs[2],batch,threshold))
  end
  
return feature