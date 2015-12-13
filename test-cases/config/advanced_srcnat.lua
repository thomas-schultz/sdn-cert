--[[
  Test:   static source-NAT implementation with random source-port
  Result: throughput and latency
]]

require "benchmark_config"
  
local Test = {} 

Test.require = "match_ethertype match_ipv4 modify_ipv4 modify_l4port"
 
Test.loadGen = "moongen"
Test.files   = "load-latency.lua"
Test.lgArgs  = "$file=1 $id $link=1 $link=2 $duration $rate $numIP $pktSize"
Test.ofArgs  = "$numIP $link=1 $link=2"

Test.settings = {
  BASE_IP = "10.0.0.0",
  SRC_IP = "128.0.0.1",
  minPort = 1204,
  maxPort = 65535,
}

Test.flowEntries = function(flowData, numIP, inPort, outPort)
    math.randomseed(os.time())
    local ip = BenchmarkConfig.IP.parseIP(Test.settings.BASE_IP)
    for i=1,tonumber(numIP) do
      local matchIP = BenchmarkConfig.IP.getIP(ip)
      local newPort = math.random(Test.settings.minPort, Test.settings.maxPort)
      local flow = string.format("ip,udp,in_port=%d,nw_src=%s, actions=mod_nw_src=%s,mod_tp_src=%d,output:%d", inPort, matchIP, Test.settings.SRC_IP, newPort, outPort)
      table.insert(flowData.flows, flow)
      BenchmarkConfig.IP.incAndWrap(ip)
    end
  end
  
Test.metric = "load-latency"

return Test