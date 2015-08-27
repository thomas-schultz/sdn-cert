local dpdk    = require "dpdk"
local memory  = require "memory"
local device  = require "device"
local stats   = require "stats"

-- settings
local bufsize = 32          -- buff size for sending
local pktsize = 62          -- in bytes
local iterations = 8        -- pkt count = bufsize * iterations
local max_pkt_loss = 0.05   -- tolerated packet loss for success 
local timeout = 5           -- in seconds

-- changes here need must match with the openf-low script, due to hardcoded values
local SRC_MAC   = "aa:bb:cc:dd:ee:ff"
local DST_MAC   = "ff:ff:ff:ff:ff:ff"
local MOD_MAC   = "ff:ee:dd:cc:bb:aa"
local SRC_IP    = {ipv4 = "10.0.0.1", ipv6 = "fc00:0000:0000:0000:0000:0000:0000:0001"}
local DST_IP    = {ipv4 = "10.0.0.2", ipv6 = "fc00:0000:0000:0000:0000:0000:0000:0002"}
local MOD_IP    = {ipv4 = "10.0.0.3", ipv6 = "fc00:0000:0000:0000:0000:0000:0000:0003"}
local SRC_PORT  = 1234
local DST_PORT  = 4321
local MOD_PORT  = 5555
local TOS       = 0
local MOD_TOS   = 16
local TTL       = 64

function master(featureName, txPort, ...)
  local rxPorts = {...}
  if not featureName or not txPort or not rxPorts then
    return print("usage: featureName txPort rxPorts ... ")
  end
  local txDev = device.config{
    port = txPort,
    rxQueues = 1,
    txQueues = 1,
  }
  local rxDevs = {}
  for i=1,#rxPorts do
    rxDevs[i] = device.config{
      port = rxPorts[i],
      rxQueues = 1,
      txQueues = 1,
      mempool = memory.createMemPool{n = 2^16}
    }
  end
  device.waitForLinks()
  txDev:getTxQueue(0):setRate(100 - (pktsize + 4) * 8 / 1000)
  
  local ip6 = string.find(featureName, "ipv6") ~= nil
  dpdk.launchLua("featureTxSlave", featureName, txDev, ip6)
  dpdk.launchLua("featureRxSlave", featureName, rxDevs, ip6)
  dpdk.waitForSlaves()
end

local logical_type = {
  ["all"]  = function(cond1, cond2) return not (cond1 == nil and cond2 == nil) and (cond1 == nil or cond1) and (cond2 == nil or cond2) end,
  ["any"]  = function(cond1, cond2) return cond1 or (cond2 ~= nil and cond2) end,
  ["one"]  = function(cond1, cond2) return ((cond1 or cond2) and not (cond1 and cond2)) or false end,
}

local switch = {
  ["match_inport"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_ethertype"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_l2addr"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_tos"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_ttl"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_ipv4"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_ipv6"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_l3proto"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["match_l4port"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
  },
  ["modify_l2addr"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.src_mac == MOD_MAC or pkt.dst_mac == MOD_MAC) end,
  },
  ["modify_tos"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.tos == MOD_TOS) end,
  },
  ["modify_ttl"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.ttl == TTL - 1) end,
  },
  ["modify_ipv4"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) end,
  },
  ["modify_ipv6"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv6 or pkt.dst_ip == MOD_IP.ipv6) end,
  },
  ["modify_l4port"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.src_port == MOD_PORT or pkt.dst_port == MOD_PORT) end, 
  },
  ["action_normal"] = {
    ctr_type        = "all",
    desired_ctr     = 1,
  },
  ["action_flood"] = {
    ctr_type        = "all",
    desired_ctr     = 1,
  },
  ["action_duplicate"] = {
    ctr_type        = "any",
    desired_ctr     = 2,
  },
  ["action_setfield"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.ttl == 1) end,
 
  },
  ["action_group_all"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) if (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip ~= MOD_IP.ipv4) then return 1
                                     elseif (pkt.src_ip ~= MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) then return 2
                                     else return 0 end end,
    check_classes   = function (ctrs) return (ctrs[1] > block_size or ctrs[2] > block_size) end, 
  },
  ["action_group_indirect"] = { 
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) end,
  },
  ["action_group_select"] = {
    ctr_type        = "any",
    desired_ctr     = 1,
    pkt_classifier  = function (pkt) if (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip ~= MOD_IP.ipv4) then return 1
                                     elseif (pkt.src_ip ~= MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) then return 2
                                     else return 0 end end,
    check_classes   = function (ctrs) return (ctrs[1] > block_size or ctrs[2] > block_size) end,
  },
}

-- examines the packet counter and checks the packet. Returns test result and reason string.
function evaluate(featureName, rxPkts, rxCtrs, ip6)
  local eval = switch[featureName]
  if (eval == nil) then return "Invalid feature name" end
  -- override this function if necessary 
  if (eval.customEvaluate ~= nil) then return eval.customEvaluate(rxPkts, rxCtrs, ip6) end
  -- import custom settings from switch table
  if (eval.max_pkt_loss ~= nil) then max_pkt_loss = eval.max_pkt_loss end
  if (eval.timeout ~= nil) then timeout = eval.timeout end
  block_size = bufsize * iterations * (1-max_pkt_loss)
  
  -- check packet counters
  if (eval.ctr_type == nil) then return "Invalid counter type" end
  local logical_op = logical_type[eval.ctr_type]
  local success = nil
  for i=1,#rxCtrs do
    local measured_ctr = select(4, rxCtrs[i]:getStats())
    success = logical_op(success, (eval.desired_ctr ~= nil and measured_ctr > eval.desired_ctr * block_size))
  end
  if (success ~= true) then return "Packet counters below threshold" end
  if (eval.pkt_classifier == nil) then return "passed" end
  
  --inspect received packets
  local measured_pkt_ctr = {[0] = 0}
  if (eval.classes == nil) then eval.classes = 1 end  
  for p=1,#rxPkts do
    local pkt = rxPkts[p]
    local index = eval.pkt_classifier(pkt)
    -- boolean mapping: false=0, true=1
    if (index == true) then index = 1 elseif (index == false) then index = 0 end
    if (measured_pkt_ctr[index] == nil) then measured_pkt_ctr[index] = 1 else measured_pkt_ctr[index] = measured_pkt_ctr[index] + 1 end
  end
  if (measured_pkt_ctr[0] > 0) then return "Received invalid packets ("..tostring(measured_pkt_ctr[0])..")" end
  local check_classes = eval.check_classes
  if (check_classes == nil) then check_classes = function (ctrs) return ctrs[1] > 0 end end
  if (not check_classes(measured_pkt_ctr)) then return "Match counter check failed" end
  return "passed"
end

function saveResult(featureName, message)
  local out_file = "../results/feature_" .. featureName .. ".result"
  local out = io.open(out_file, "w")
  out:write(message)
  io.close(out)
end

function dumpTxPacket(featureName, txPkt)
  local out_file = "../results/feature_" .. featureName .. "_tx.dump"
  local out = io.open(out_file, "w")
  for k,v in pairs(txPkt) do
    out:write(k.."="..v..", ")
  end
  out:write("\n")
  io.close(out)
end

function dumpRxPackets(featureName, rxPkts)
  local out_file = "../results/feature_" .. featureName .. "_rx.dump"
  local out = io.open(out_file, "w")
  for i=1,#rxPkts do
    out:write("packet="..tostring(i).."  ")
    for k,v in pairs(rxPkts[i]) do
      out:write(k.."="..v..", ")
    end
    out:write("\n")
  end
  io.close(out)
end

function fillUdpPacket(buf, len, ip6)
  local udpPacket
  if (ip6) then
    return fillUdp6Packet(buf, len)
  else
    return fillUdp4Packet(buf, len)
  end
end

function fillUdp6Packet(buf, len)
  buf:getUdp6Packet():fill{
    ethSrc = SRC_MAC,
    ethDst = DST_MAC,
    ip6TrafficClass = TOS,
    ip6TTL = TTL,
    ip6Src = SRC_IP.ipv6,
    ip6Dst = DST_IP.ipv6,
    udpSrc = SRC_PORT,
    udpDst = DST_PORT,
    pktLength = len
  }
end

function fillUdp4Packet(buf, len)
  buf:getUdp4Packet():fill{
    ethSrc = SRC_MAC,
    ethDst = DST_MAC,
    ip4TOS = TOS,
    ip4TTL = TTL,
    ip4Src = SRC_IP.ipv4,
    ip4Dst = DST_IP.ipv4, 
    udpSrc = SRC_PORT,
    udpDst = DST_PORT,
    pktLength = len
  }
end

-- retrieves data from packet buffer
function retrieveUdpPacket(packet, inport, ip6)
  local ether_pkt = packet:getEthernetPacket(not ip6)
  local ip_pkt = packet:getIPPacket(not ip6)
  local udp_pkt = packet:getUdpPacket()
  local pkt = {}
  
  pkt.inport = inport
  pkt.eth_type = ether_pkt.eth:getType()
  pkt.src_mac = ether_pkt.eth:getSrcString()
  pkt.dst_mac = ether_pkt.eth:getDstString()
  if (ip6) then
    pkt.tos = ip_pkt.ip6:getTrafficClass()
    pkt.ttl = ip_pkt.ip6:getTTL()
    pkt.src_ip = ip_pkt.ip6:getSrcString()
    pkt.dst_ip = ip_pkt.ip6:getDstString()
  else
    pkt.tos = ip_pkt.ip4:getTOS()
    pkt.ttl = ip_pkt.ip4:getTTL()
    pkt.src_ip = ip_pkt.ip4:getSrcString()
    pkt.dst_ip = ip_pkt.ip4:getDstString()
  end
  pkt.src_port = udp_pkt.udp:getSrcPort()
  pkt.dst_port = udp_pkt.udp:getDstPort()
  return pkt
end

-- Creates fixed UDP packets
function featureTxSlave(featureName, txDev, ip6)
  local mempool = memory.createMemPool(function(buf)
    fillUdpPacket(buf, pktsize, ip6)
  end)  
  local txQueue = txDev:getTxQueue(0)
  local txCtr = stats:newDevTxCounter(txDev, "plain")
  local txBuf = mempool:bufArray(bufsize)
  
  for i=1,iterations do
    txBuf:alloc(pktsize)
    for i, buf in ipairs(txBuf) do
      local pkt = buf:getUdpPacket(not ip6)
    end
    txBuf:offloadUdpChecksums(not ip6)
    txQueue:send(txBuf)
  end  
  txCtr:finalize()
  dumpTxPacket(featureName, retrieveUdpPacket(txBuf[1], i, ip6))
end

-- Receives all packets and evaluates test conditions
function featureRxSlave(featureName, rxDevs, ip6)
  local mempool = memory.createMemPool(function(buf)
    fillUdpPacket(buf, pktsize, ip6)
  end)
  local rxPkts = {}
  local rxBuf = mempool:bufArray()
  local rxQueues = {}
  local rxCtrs = {}
  for i=1,#rxDevs do
    rxQueues[i] = rxDevs[i]:getRxQueue(0) 
    rxCtrs[i] = stats:newDevRxCounter(rxDevs[i], "plain")
  end
  local timeout = dpdk.getTime() + timeout
    
  while dpdk.running() do
    for i=1,#rxDevs do
      local rx = rxQueues[i]:tryRecv(rxBuf, 0)
      for j=1,rx do
        --rxBuf[j]:getUdpPacket():dump()
        table.insert(rxPkts, retrieveUdpPacket(rxBuf[j], i, ip6))
      end
    end
    if (dpdk.getTime() > timeout) then break end
  end
  for i=1,#rxDevs do
    rxCtrs[i]:finalize()
  end
  saveResult(featureName, evaluate(featureName, rxPkts, rxCtrs, ip6))
  dumpRxPackets(featureName, rxPkts)
end