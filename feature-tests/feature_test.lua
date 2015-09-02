package.path = package.path .. ';../scripts/?.lua'

local dpdk    = require "dpdk"
local memory  = require "memory"
local device  = require "device"
local stats   = require "stats"
local feature = require "feature_config"

-- settings
settings = {
  bufSize = 32,          -- buff size for sending
  pktSize = 80,          -- in bytes
  iterations = 1,        -- pkt count = bufsize * iterations
  maxDeviation = 0.05,   -- max percental deviation
  timeout = 5,           -- in seconds
  config = nil,          -- config loaded from feature file
  batchSize = -1,        -- packets in one batch (bufSize*iterations)
}


function master(featureName, txPort, ...)
  local rxPorts = {txPort, ...}
  if not featureName or not txPort or not rxPorts then
    return print("usage: featureName txPort rxPorts ... ")
  end
  importSettings(featureName)
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
  txDev:getTxQueue(0):setRate(100 - (settings.pktSize + 4) * 8 / 1000)
  
  dpdk.launchLua("featureTxSlave", featureName, txDev)
  dpdk.launchLua("featureRxSlave", featureName, rxDevs)
  dpdk.waitForSlaves()
end

function importSettings(name)
  local config = feature.feature[name]
  if (not config) then return end
  settings.config = config
  local settings_ = config.settings
  if (not settings_) then return end
  for k,v in pairs(settings_) do
    settings[k] = v
  end
  settings.batchSize = settings.bufSize * settings.iterations
end

-- examines the packet counter and checks the packet. Returns test result string.
function evaluate(featureName, rxPkts, rxCtrs)
  local eval = settings.config.evalCrit
  if (eval == nil) then
    return "Invalid or incomplete feature, check feature implementation" end
  -- override the complete evaluate function if necessary 
  if (eval.customEvaluate) then
    return eval.customEvaluate(rxPkts, rxCtrs) end
  
  -- check packet counters
  if (not eval.ctrType) then
    return "Invalid counter type, check feature implementation" end
  if (not eval.desiredCtr) then
    return "Invalid value for desired Counter, check feature implementation" end
  
  -- if not specified, use default threshold value: desiredbatchSize * tolerance value
  local desiredBatchSize = eval.desiredCtr * settings.batchSize
  if (not settings.threshold) then
    settings.threshold = math.floor(desiredBatchSize * settings.maxDeviation) end
  local logicalOp = feature.logicalOps[eval.ctrType]
    
  local info = ""
  local success = nil
  for i=1,#rxCtrs do
    local measuredCtr = select(4, rxCtrs[i]:getStats())
    info = info .. "rx:" .. i .." " .. measuredCtr .. "/" .. desiredBatchSize .. "/" .. settings.threshold .. " "
    success = logicalOp(success, (math.abs(desiredBatchSize - measuredCtr) <= settings.threshold))
  end
  if (success ~= true) then return "Packet counters exceeded threshold, rx/ref/thld" .. info end
  if (eval.pkt_classifier == nil) then return "passed" end
  
  --inspect received packets
  local measured_pkt_ctr = {[0] = 0} 
  for p=1,#rxPkts do
    local pkt = rxPkts[p]
    local index = eval.pkt_classifier(pkt)
    -- boolean mapping: false=0, true=1
    if (index == true) then index = 1 elseif (index == false) then index = 0 end
    if (measured_pkt_ctr[index] == nil) then measured_pkt_ctr[index] = 1 else measured_pkt_ctr[index] = measured_pkt_ctr[index] + 1 end
  end
  if (measured_pkt_ctr[0] > 0) then return "Received invalid packets ["..tostring(measured_pkt_ctr[0]).."/" .. settings.batchSize .."]"  end
  local evalCounter = eval.evalCounter
  -- if not specified, apply default check function: pass if any packet is received
  if (evalCounter == nil) then evalCounter = feature.feature.default.evalCounter end
  if (not evalCounter(measured_pkt_ctr, settings.threshold)) then return "Match counter check failed" end
  return "passed"
end

function saveResult(featureName, message)
  local out_file = "../results/feature_" .. featureName .. ".result"
  local out = io.open(out_file, "w")
  out:write(message)
  io.close(out)
end

function fillPacket(buf, len, proto, ip6)
  local pkt
  if (proto == feature.enum.PROTO.udp) then
    pkt = buf:getUdpPacket(not ip6)
  elseif (proto == feature.enum.PROTO.tcp) then
    pkt = buf:getTcpPacket(not ip6)
  else
    buf:getEthPacket():fill{
      ethType = feature.pkt.ETH_TYPE,
      ethSrc  = feature.pkt.SRC_MAC,
      ethDst  = feature.pkt.DST_MAC,
    }
    return
  end
  pkt:fill{
    ethSrc  = feature.pkt.SRC_MAC,
    ethDst  = feature.pkt.DST_MAC,
    ip4TOS  = feature.pkt.TOS,
    ip4TTL  = feature.pkt.TTL,
    ip4Src  = feature.pkt.SRC_IP4,
    ip4Dst  = feature.pkt.DST_IP4, 
    ip6TrafficClass = feature.pkt.TOS,
    ip6TTL  = feature.pkt.TTL,
    ip6Src  = feature.pkt.SRC_IP6,
    ip6Dst  = feature.pkt.DST_IP6,
    udpSrc  = feature.pkt.SRC_PORT,
    udpDst  = feature.pkt.DST_PORT,
    tcpSrc  = feature.pkt.SRC_PORT,
    tcpDst  = feature.pkt.DST_PORT,
    pktLength = len
  }
end

-- retrieves data from packet buffer
function retrievePacket(packet, dev)
  local pkt = {}
  pkt.id = -1
  pkt.dev = dev
  local ethPkt = packet:getEthernetPacket()
  pkt.eth_type_str = ethPkt.eth:getTypeString()
  pkt.eth_type     = ethPkt.eth:getType()
  pkt.src_mac      = ethPkt.eth:getSrcString()
  pkt.dst_mac      = ethPkt.eth:getDstString()
  local curPkt = ethPkt
  if (pkt.eth_type == feature.enum.ETH_TYPE.ip6) then
    local ip6Pkt = packet:getIPPacket(false).ip6
    pkt.tos       = ip6Pkt:getTrafficClass()
    pkt.ttl       = ip6Pkt:getTTL()
    pkt.src_ip    = ip6Pkt:getSrcString()
    pkt.dst_ip    = ip6Pkt:getDstString()
    pkt.proto     = ip6Pkt:getNextHeader()
    pkt.proto_str = ip6Pkt:getNextHeaderString()
    curPkt = ip6Pkt
  elseif (pkt.eth_type == feature.enum.ETH_TYPE.ip4) then
    local ip4Pkt = packet:getIPPacket(true).ip4
    pkt.tos       = ip4Pkt:getTOS()
    pkt.ttl       = ip4Pkt:getTTL()
    pkt.src_ip    = ip4Pkt:getSrcString()
    pkt.dst_ip    = ip4Pkt:getDstString()
    pkt.proto     = ip4Pkt:getProtocol()
    pkt.proto_str = ip4Pkt:getProtocolString()
    curPkt = ip4Pkt
  else
    pkt.id       = curPkt.payload.uint32[0]
    return pkt
  end
  if (pkt.proto == feature.enum.PROTO.udp) then
    local udpPkt = packet:getUdpPacket()
    pkt.src_port = udpPkt.udp:getSrcPort()
    pkt.dst_port = udpPkt.udp:getDstPort()
    pkt.id       = udpPkt.payload.uint32[0]
    curPkt = udpPkt
  elseif (pkt.proto == feature.enum.PROTO.tcp) then
    local tcpPkt = packet:getTcpPacket()
    pkt.src_port = tcpPkt.tcp:getSrcPort()
    pkt.dst_port = tcpPkt.tcp:getDstPort()
    pkt.id       = tcpPkt.payload.uint32[0]
    curPkt = tcpPkt 
  else
    pkt.id       = curPkt.payload.uint32[0]
    return pkt
  end
  pkt.id       = curPkt.payload.uint32[0]
  return pkt
end

-- Creates fixed UDP packets
function featureTxSlave(featureName, txDev)
  importSettings(featureName)
  local txQueue = txDev:getTxQueue(0)
  local txCtr = stats:newDevTxCounter(txDev, "plain")
  local txDump = io.open("../results/feature_" .. featureName .. "_tx.dump", "w")

  feature.createPkt()
  for n=1,2 do
    local ip6 = settings.ip6 ~= nil and settings.ip6 == true 
    local mempool = memory.createMemPool(function(buf)
        fillPacket(buf, settings.pktSize, feature.pkt.PROTO, ip6)
      end) 
    local txBuf = mempool:bufArray(settings.bufSize)
    for i=1,settings.iterations do
      txBuf:alloc(settings.pktSize)
      for p, buf in ipairs(txBuf) do
        local pkt = nil
        if (n == 1) then pkt = buf:getUdpPacket(not ip6)
        else pkt = buf:getTcpPacket(not ip6) end
        local id = (n-1)*settings.batchSize + (i-1)*settings.bufSize + p
        pkt.payload.uint32[0] = id
        txDump:write("Packet " .. id .. "\n")
        buf:dump(txDump)
      end
      if (feature.pkt.PROTO == FeatureConfig.enum.PROTO.udp) then
        txBuf:offloadUdpChecksums(not ip6)
      elseif (feature.pkt.PROTO == FeatureConfig.enum.PROTO.tcp) then
        txBuf:offloadTcpChecksums(not ip6)
      end
      txQueue:send(txBuf)
    end
    local modifyPkt = settings.config.modifyPkt
    if (modifyPkt) then modifyPkt() else break end
  end    
  txCtr:finalize()
  io.close(txDump)
end

-- Receives all packets and evaluates test conditions
function featureRxSlave(featureName, rxDevs, ip6)
  importSettings(featureName)
  local mempool = memory.createMemPool(function(buf)
    fillPacket(buf, settings.pktSize, feature.enum.PROTO.udp, ip6)
  end)
  local rxBuf = mempool:bufArray()
  local rxQueues = {}
  local rxCtrs = {}
  for i=1,#rxDevs do
    rxQueues[i] = rxDevs[i]:getRxQueue(0) 
    rxCtrs[i] = stats:newDevRxCounter(rxDevs[i], "plain")
  end
  local timeout = dpdk.getTime() + settings.timeout
  local rxPkts = {}
  local rxDump = io.open("../results/feature_" .. featureName .. "_rx.dump", "w")
    
  while dpdk.running() do
    for i=1,#rxDevs do
      local rx = rxQueues[i]:tryRecv(rxBuf, 0)
      for j=1,rx do
        local pkt = rxBuf[j]
        local recv = retrievePacket(pkt, i)
        table.insert(rxPkts, recv)
        rxDump:write("Packet " .. recv.id .. "\n")
        pkt:dump(rxDump)
      end
    end
    if (dpdk.getTime() > timeout) then break end
  end
  for i=1,#rxDevs do
    rxCtrs[i]:finalize()
  end
  io.close(rxDump)
  saveResult(featureName, evaluate(featureName, rxPkts, rxCtrs))
end