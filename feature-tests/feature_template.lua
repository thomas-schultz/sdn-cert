--[[
  Feature template file
]]

-- imports all needed function and default values, do not remove!
require "feature_config"

-- creates new Feature from feature_config file, do not remove!
local Feature = FeatureConfig.new()

-- required OpenFlow Version
Feature.require = "OpenFlow10"
-- what does the specification say about it
Feature.state   = "required"
  
-- load generating tool
Feature.loadGen = "moongen"
-- list of files to copy to the load generator host, use space as separator or specify as table
Feature.files   = "feature_test.lua"
-- argument list for the load generator, use space as separator or specify as table
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
-- argument list which will be mapped and than passed to the flowEntries function, can be omitted
Feature.ofArgs  = "$link=2"

-- sepcifies the packet, either use the default, or define your own
Feature.pkt  = Feature.getDefaultPkt()
-- modifing certain fields of the packets is possible 
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip6

-- allows to specify settings, default values can be overwritten, may be omitted
-- can be used to store feature relevant information, like IPs, ports etc
Feature.settings = {
  txIterations = 1,
  new_ETH_TYPE = Feature.enum.ETH_TYPE.wol,
  new_SRC_IP4 = "10.0.2.1",
  new_DST_IP4 = "10.0.2.2",
}
-- shortcut for further use, keeps the definition simple
local conf = Feature.settings

-- creating of the flow entries in flowData = { flows, groups, meters }
Feature.flowEntries = function(flowData, link2)
    table.insert(flowData.flows, "actions=output:" .. link2)
    table.insert(flowData.groups, "group_id=1,type=all,bucket=DROP")
    table.insert(flowData.meters, "meter=1,kbps,burst,band=type=drop,rate=1000")
  end
 
-- modify function, called after every iteration, ignored if only one pass is used, may be omitted  
Feature.modifyPkt = function(pkt, iteration)
    pkt.ETH_TYPE = conf.new_ETH_TYPE -- simplified version of 'Feature.settings.new_ETH_TYPE'
    pkt.PROTO = Feature.enum.PROTO.undef
  end

-- packet classifier functions, every entry evaluates to a boolean value, then the packet
-- get classified with the index of this function in the table, may be omitted 
Feature.pktClassifier = {
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP4 and pkt.dst_ip ~= conf.new_DST_IP4) end,
    function(pkt) return (pkt.src_ip ~= conf.new_SRC_IP4 and pkt.dst_ip == conf.new_DST_IP4) end,
  }

-- function of how the classified packet counters should be compared, returns test result, may be omitted
Feature.evalCounters = function(ctrs, batch, threshold)
    return (Feature.eval(ctrs[1],batch,threshold) or Feature.eval(ctrs[2],batch,threshold))
  end
  
return Feature