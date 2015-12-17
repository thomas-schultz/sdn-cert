--[[
  Feature test for modifying the IPv6 src and dst field
]]

require "feature_config"

local Feature = FeatureConfig.new()

Feature.require = "OpenFlow12"
Feature.state   = "optional"
  
Feature.loadGen = "moongen"
Feature.files   = "feature_test.lua"
Feature.lgArgs  = "$file=1 $name $link=1 $link=2"
Feature.ofArgs  = "$link=2"
    
Feature.pkt = Feature.getDefaultPkt()
Feature.pkt.ETH_TYPE = Feature.enum.ETH_TYPE.ip6

Feature.config{
  new_SRC_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0001",
  new_DST_IP6 = "fc00:0000:0000:0000:0000:0000:0002:0002",
}
local conf = Feature.settings

Feature.flowEntries = function(flowData, outPort)
    table.insert(flowData.flows, string.format("ipv6, actions=set_field=%s->ipv6_src, set_field:%s->ipv6_dst, output:%s", conf.new_SRC_IP6, conf.new_DST_IP6, outPort))
  end

FeatureConfig.pktClassifier = {
    function(pkt) return (pkt.src_ip == conf.new_SRC_IP6 and pkt.dst_ip == conf.new_DST_IP6) end,
  }

return Feature