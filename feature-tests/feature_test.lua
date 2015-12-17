package.path = package.path .. ';../scripts/?.lua'

local dpdk    = require "dpdk"
local memory  = require "memory"
local device  = require "device"
local stats   = require "stats"

feature = {}
settings = {}

function master(featureName, ...)
  local ports = {...}
  if (not featureName or #ports < 1 ) then
    return print("usage: featureName tx/rxPorts ... ")
  end
  importFeature(featureName)
  local devs = {}
  for i=1,#ports do
    devs[i] = device.config{
      port = ports[i],
      rxQueues = 1,
      txQueues = 1,
      mempool = memory.createMemPool{n = 2^16}
    }
  end
  device.waitForLinks()
  for i=1,#ports do
    devs[i]:getTxQueue(0):setRate(100 - (settings.pktSize + 4) * 8 / 1000)
  end
  
  dpdk.launchLua("featureTxSlave", featureName, devs, ports)
  dpdk.launchLua("featureRxSlave", featureName, devs, ports)
  dpdk.waitForSlaves()
end

function importFeature(name)
  feature = require(name)
  settings = feature.settings
  settings.batchSize = settings.bufSize * settings.loops
end

-- examines the packet counter and checks the packet. Returns test result string.
function evaluate(featureName, rxPkts, rxCtrs, ports)
  -- override the complete evaluate function if necessary 
  if (feature.customEvaluate) then
    return feature.customEvaluate(rxPkts, rxCtrs, ports) end
  
  -- check packet counters
  if (not settings.ctrType) then
    return "FAILED: Invalid counter type, check feature configuration" end
  if (not settings.desiredCtr) then
    return "FAILED: Invalid value for desired counter, check feature configuration" end
  
  -- if not specified, use default threshold value: desiredbatchSize * tolerance value
  local desiredBatchSize = settings.desiredCtr * settings.batchSize
  settings.maxDeviation = settings.maxDeviation or 0
  settings.threshold = math.max(settings.threshold or 0, math.ceil(desiredBatchSize * settings.maxDeviation))
  local logicalOp = feature.logicalOps[settings.ctrType]
    
  print("Checking device packet counters")
  local info = ""
  local success = nil
  for i=settings.firstRxDev,#rxCtrs do
    local measuredCtr = select(4, rxCtrs[i]:getStats())
    print("device " .. ports[i] ..":  rx = " .. measuredCtr .. ", testing | rx - " .. desiredBatchSize .. " | <= " .. settings.threshold)
    success = logicalOp(success, (math.abs(desiredBatchSize - measuredCtr) <= settings.threshold))
  end
  if (success ~= true) then return "FAILED: packet counters exceeded threshold!" end
  
  --inspect received packets
  local measuredPktsCtrs = {[0] = 0}
  for i=1,#feature.pktClassifier do measuredPktsCtrs[i] = 0 end
  
  print("Checking classified packet counters")
  for p=1,#rxPkts do
    local pkt = rxPkts[p]
    local index = 0
    for i=1,#feature.pktClassifier do
      if (feature.pktClassifier[i](pkt)) then index = i end
    end
    measuredPktsCtrs[index] = measuredPktsCtrs[index] + 1
  end
  if (measuredPktsCtrs[0] > 0) then
    return "Received invalid packets ["..tostring(measuredPktsCtrs[0]).."/" .. settings.batchSize .."]"  end
    
  for i=1,#measuredPktsCtrs do
    print("class: " .. tostring(i) .. " = " .. tostring(measuredPktsCtrs[i]))
  end

  -- apply counter check function
  if (not feature.evalCounters (measuredPktsCtrs, desiredBatchSize, settings.threshold)) then
    return "FAILED: classified packet counter mismatch!" end
  -- everything was as expected, then test is passed 
  return "passed"
end

function savePattern(featureName, rxPattern, desiredPkts)
  local outFile = "../results/feature_" .. featureName .. "_rx-pattern"
  local out = io.open(outFile, "w")
  local pattern = ""
  for i=1,math.max(desiredPkts, #rxPattern) do
    if (rxPattern[i] and rxPattern[i] > 0) then pattern = pattern .. rxPattern[i]
    else pattern = pattern .. "-" end
    if (string.len(pattern) >= 80) then
      out:write(pattern .. "\n")
      pattern = ""
    end
  end
  if (string.len(pattern) > 0) then out:write(pattern .. "\n") end
  io.close(out)
end

function saveResult(featureName, message)
  local outFile = "../results/feature_" .. featureName .. "_result"
  local out = io.open(outFile, "w")
  out:write(message)
  io.close(out)
end

function createPacket(buf, ethType, proto)
  local ip6 = (ethType == feature.enum.ETH_TYPE.ip6)
  if (proto == feature.enum.PROTO.udp) then return buf:getUdpPacket(not ip6) end
  if (proto == feature.enum.PROTO.tcp) then return buf:getTcpPacket(not ip6) end
  if (ethType == feature.enum.ETH_TYPE.ip4) then return buf:getIP4Packet() end
  if (ethType == feature.enum.ETH_TYPE.ip6) then return buf:getIP6Packet() end
  return buf:getEthPacket()
end

function fillPacket(buf, prototype, len)
  local pkt = createPacket(buf, prototype.ETH_TYPE, prototype.PROTO)
  pkt:fill{
    ethType = prototype.ETH_TYPE,
    ethSrc  = prototype.SRC_MAC,
    ethDst  = prototype.DST_MAC,
    ip4TOS  = prototype.TOS,
    ip4TTL  = prototype.TTL,
    ip4Src  = prototype.SRC_IP4,
    ip4Dst  = prototype.DST_IP4, 
    ip6TrafficClass = prototype.TOS,
    ip6TTL  = prototype.TTL,
    ip6Src  = prototype.SRC_IP6,
    ip6Dst  = prototype.DST_IP6,
    udpSrc  = prototype.SRC_PORT,
    udpDst  = prototype.DST_PORT,
    tcpSrc  = prototype.SRC_PORT,
    tcpDst  = prototype.DST_PORT,
    pktLength = len
  }
end

function setPayload(packet, payload)
  local ip6
  local ethType = packet:getEthernetPacket().eth:getType()
  if (ethType == feature.enum.ETH_TYPE.ip6) then ip6 = true
  elseif (ethType == feature.enum.ETH_TYPE.ip4) then ip6 = false
  else
    packet:getEthernetPacket().payload.uint32[0] = payload
    return
  end
  local proto = nil
  if (ip6) then proto = packet:getIPPacket(false).ip6:getNextHeader()
  else proto = packet:getIPPacket().ip4:getProtocol() end
  
  if (proto == feature.enum.PROTO.udp) then
    packet:getUdpPacket(not ip6).payload.uint32[0] = payload
  elseif (proto == feature.enum.PROTO.tcp) then
    packet:getTcpPacket(not ip6).payload.uint32[0] = payload
  else
    packet:getIPPacket(not ip6).payload.uint32[0] = payload
  end
end

-- retrieves data from packet buffer
function retrievePacket(packet, dev, ports)
  local pkt = {}
  pkt.id = -1
  pkt.devId = dev
  pkt.devPort = ports[dev]
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
    pkt.id = curPkt.payload.uint32[0]
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
    pkt.id = curPkt.payload.uint32[0]
    return pkt
  end
  pkt.id = curPkt.payload.uint32[0]
  return pkt
end

-- Creates fixed packets
function featureTxSlave(featureName, txDevs, ports)
  importFeature(featureName)
  local txQueues = {}
  local txCtrs = {}
  
  -- check how many tx iterations are performed
  local txSteps = settings.txIterations
  if (not txSteps or txSteps <= 0) then txSteps = #txDevs end
  
  for i=1,#txDevs do txQueues[i] = txDevs[i]:getTxQueue(0) end
  local txDump = io.open("../results/feature_" .. featureName .. "_tx-dump", "w")

  local learnFrames = settings.learnFrames or 0
  if (learnFrames > 0) then
    local learnPkt = feature.getPkt(feature.pkt)
    local learnTime = settings.learnTime or 500
    -- send learning packet for the switch
    for n=1,txSteps do
      local mempool = memory.createMemPool(function(buf)
          fillPacket(buf, learnPkt, settings.pktSize)
        end)
      local learnBuf = mempool:bufArray(learnFrames)
      print("Sending " .. tostring(learnFrames) ..  " learning Frames in " .. learnTime .. " msec")
      learnBuf:alloc(settings.pktSize)
      txQueues[settings.txDev]:send(learnBuf)
      feature.modifyPkt(learnPkt, n)
    end
    dpdk.sleepMillis(learnTime)
  end

  -- start actual feature traffic
  local txPkt = feature.getPkt(feature.pkt)
  local id = 0
  for n=1,txSteps do
    local ip6 = feature.isIPv6(txPkt)
    local mempool = memory.createMemPool(function(buf)
        fillPacket(buf, txPkt, settings.pktSize)
      end)    
    txCtrs[settings.txDev] = stats:newDevTxCounter(txDevs[settings.txDev], "plain") 
      
    -- start actual feature traffic
    local txBuf = mempool:bufArray(settings.bufSize)
    for i=1,settings.loops do
      txBuf:alloc(settings.pktSize)
      for p, buf in ipairs(txBuf) do
        id = id + 1
        setPayload(buf, id)
        txDump:write("Packet " .. p .. " / " .. tostring(settings.batchSize) .. " - " .. id .. " / " .. tostring(txSteps*settings.batchSize) .. " on dev " .. tostring(ports[n]) .. "\n")
        buf:dump(txDump)
      end
      if (txPkt.PROTO == feature.enum.PROTO.udp) then
        txBuf:offloadUdpChecksums(not ip6)
      elseif (txPkt.PROTO == feature.enum.PROTO.tcp) then
        txBuf:offloadTcpChecksums(not ip6)
      end
      txQueues[settings.txDev]:send(txBuf)
    end
    txCtrs[settings.txDev]:finalize()
    feature.modifyPkt(txPkt, n)
  end
  io.close(txDump)
end

-- Receives all packets and evaluates test conditions
function featureRxSlave(featureName, rxDevs, ports)
  importFeature(featureName)
  local mempool = memory.createMemPool(function(buf)
    fillPacket(buf, feature.pkt, settings.pktSize)
  end)
  local rxBuf = mempool:bufArray()
  local firstRxDev = settings.firstRxDev or 1
  local rxQueues = {}
  local rxCtrs = {}
  for i=firstRxDev,#rxDevs do rxQueues[i] = rxDevs[i]:getRxQueue(0) end 
  
  --wait until the learning packets are received and discarded
  local learnFrames = settings.learnFrames or 0
  if (learnFrames > 0) then 
    local learnBuf = mempool:bufArray()
    dpdk.sleepMillis(settings.learnTime or 500)
    for i=settings.firstRxDev,#rxDevs do 
      local rx = rxQueues[i]:tryRecv(learnBuf, 0)
      local discard = learnFrames * (settings.txIterations or 1)
      print("Discarded " .. tostring(rx) .. "/" .. tostring(discard) .. " learning frames on device " .. tostring(ports[i]))
    end
  end
  
  -- initialize the counters and stuff
  for i=firstRxDev,#rxDevs do rxCtrs[i] = stats:newDevRxCounter(rxDevs[i], "plain") end
  local timeout = dpdk.getTime() + settings.timeout
  local rxPkts = {}
  local rxPattern = {}
  local rxDump = io.open("../results/feature_" .. featureName .. "_rx-dump", "w")
  local desiredPkts = settings.desiredCtr*settings.batchSize
  
  -- start actual receiving
  while dpdk.running() do
    for i=settings.firstRxDev,#rxDevs do
      local rx = rxQueues[i]:tryRecv(rxBuf, 0)
      for j=1,rx do
        local pkt = rxBuf[j]
        local recv = retrievePacket(pkt, i, ports)
        table.insert(rxPkts, recv)
        rxPattern[recv.id] = (rxPattern[recv.id] or 0) + 1
        rxDump:write("Packet " .. recv.id .. " / " .. tostring(desiredPkts) .. " (" .. tostring(settings.txIterations*settings.batchSize) .. ") on dev " .. ports[i] .. "\n")
        pkt:dump(rxDump)
      end
    end
    if (dpdk.getTime() > timeout) then break end
  end
  for i=settings.firstRxDev,#rxDevs do
    rxCtrs[i]:finalize()
  end
  io.close(rxDump)
  savePattern(featureName, rxPattern, desiredPkts)
  saveResult(featureName, evaluate(featureName, rxPkts, rxCtrs, ports))
end