--[[
  Test:   matching on all given fields of an UDP/TCP packet
          possible matches are macs, ips, proto, ports 
  Result: throughput and latency
]]

require "benchmark_config"
  
local bench = {} 

bench.require = "match_inport match_ethertype match_l2addr match_ipv4 match_l3proto match_l4port"
 
bench.loadGen = "moongen"
bench.files   = "load-latency.lua"
bench.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate 1 $pktSize"
bench.ofArgs  = "$link=1 $link=2 $filter"

bench.settings = {
  SRC_MAC = "aa:bb:cc:dd:ee:ff",
  DST_MAC = "ff:ff:ff:ff:ff:ff",
  SRC_IP = "10.0.0.0",
  DST_IP = "10.0.0.0",
  PROTO = "udp",
  SRC_PORT = 1234,
  DST_PORT = 1234,
}

bench.flowEntries = function(flowData, inPort, outPort, filterString)
    local pkt = bench.settings
    local match = string.format("in_port=%d", inPort)
    local filters = string.split(filterString, "+")
    for _,filter in pairs(filters) do
      if (filter == "macs") then
        match = string.format("%s, dl_src=%s, dl_dst=%s", match, pkt.SRC_MAC, pkt.DST_MAC)
      elseif (filter == "ips") then
        match = string.format("%s, ip, nw_src=%s, nw_dst=%s", match, pkt.SRC_IP, pkt.DST_IP)
      elseif (filter == "proto") then
        match = string.format("%s, %s", match, pkt.PROTO)
      elseif (filter == "ports") then
        match = string.format("%s, tp_src=%d, tp_dst=%d", match, pkt.SRC_PORT, pkt.DST_PORT)
      end
    end
    --local flow = string.format("%s, actions=output:%d", match, outPort)
    local flow = "in_port=1, ip, udp, dl_src=aa:bb:cc:dd:ee:ff, dl_dst=ff:ff:ff:ff:ff:ff, nw_src=10.0.0.0, nw_dst=10.0.0.0, tp_src=1234, tp_dst=1234, actions=output:2"    
    table.insert(flowData.flows, flow)
  end
  
bench.metric = "load-latency"

return bench