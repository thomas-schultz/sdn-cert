package.path = package.path .. ';../scripts/?.lua'

local dpdk    = require "dpdk"
local memory  = require "memory"
local device  = require "device"
local stats   = require "stats"
local featureCfg = require "feature_config"

settings = {}

function master(featureName, ...)
  local ports = {...}
  if (not featureName or #ports < 2 ) then
    return print("usage: featureName tx/rxPorts ... ")
  end
  importSettings(featureName)
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

function importSettings(name)
  local dft = featureCfg.feature.default.settings
  for k,v in pairs(dft) do
    settings[k] = v
  end
  local config = featureCfg.feature[name]
  settings.config = config
  local settings_ = config.settings
  if (settings_) then for k,v in pairs(settings_) do
    settings[k] = v
    end
  end
  settings.batchSize = settings.bufSize * settings.iterations
end

-- examines the packet counter and checks the packet. Returns test result string.
function evaluate(featureName, rxPkts, rxCtrs, ports)
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
  settings.threshold  =  settings.threshold or math.ceil(desiredBatchSize * settings.maxDeviation)
  local logicalOp = featureCfg.logicalOps[eval.ctrType]
    
  local info = ""
  local success = nil
  for i=settings.firstRxDev,#rxCtrs do
    local measuredCtr = select(4, rxCtrs[i]:getStats())
    info = info .. ", " .. ports[i] ..": " .. measuredCtr .. "/" .. desiredBatchSize .. "/" .. settings.threshold 
    success = logicalOp(success, (math.abs(desiredBatchSize - measuredCtr) <= settings.threshold))
  end
  if (success ~= true) then return "Packet counters exceeded threshold [dev: rx/ref/thld]" .. info end
  if (eval.pktClassifier == nil) then return "passed" end
  
  --inspect received packets
  local measuredPktsCtrs = {[0] = 0} 
  for p=1,#rxPkts do
    local pkt = rxPkts[p]
    local index = eval.pktClassifier(pkt)
    -- boolean mapping: false=0, true=1
    if (index == true) then index = 1 elseif (index == false) then index = 0 end
    measuredPktsCtrs[index] = measuredPktsCtrs[index] or 0
    measuredPktsCtrs[index] = measuredPktsCtrs[index] + 1
  end
  if (measuredPktsCtrs[0] > 0) then
    return "Received invalid packets ["..tostring(measuredPktsCtrs[0]).."/" .. settings.batchSize .."]"  end
    
  local ctrs = "["
  for i=1,#measuredPktsCtrs do ctrs = ctrs .. " " .. tostring(measuredPktsCtrs[i]) .. " " end
  ctrs = ctrs .. "]"

  -- if not specified, apply default check function: pass if any packet is received
  local evalCounter = eval.evalCounter or featureCfg.feature.default.evalCounter
  if (not evalCounter(measuredPktsCtrs, desiredBatchSize, settings.threshold)) then
    return "Classified packet counter mismatch, " .. ctrs end
  -- everything as expected, test is passed 
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
  if (proto == featureCfg.enum.PROTO.udp) then
    pkt = buf:getUdpPacket(not ip6)
  elseif (proto == featureCfg.enum.PROTO.tcp) then
    pkt = buf:getTcpPacket(not ip6)
  else
    buf:getEthPacket():fill{
      ethType = featureCfg.pkt.ETH_TYPE,
      ethSrc  = featureCfg.pkt.SRC_MAC,
      ethDst  = featureCfg.pkt.DST_MAC,
    }
    return
  end
  pkt:fill{
    ethSrc  = featureCfg.pkt.SRC_MAC,
    ethDst  = featureCfg.pkt.DST_MAC,
    ip4TOS  = featureCfg.pkt.TOS,
    ip4TTL  = featureCfg.pkt.TTL,
    ip4Src  = featureCfg.pkt.SRC_IP4,
    ip4Dst  = featureCfg.pkt.DST_IP4, 
    ip6TrafficClass = featureCfg.pkt.TOS,
    ip6TTL  = featureCfg.pkt.TTL,
    ip6Src  = featureCfg.pkt.SRC_IP6,
    ip6Dst  = featureCfg.pkt.DST_IP6,
    udpSrc  = featureCfg.pkt.SRC_PORT,
    udpDst  = featureCfg.pkt.DST_PORT,
    tcpSrc  = featureCfg.pkt.SRC_PORT,
    tcpDst  = featureCfg.pkt.DST_PORT,
    pktLength = len
  }
end

function setPayload(packet, payload)
  local ip6 = nil
  
  local ethType = packet:getEthernetPacket().eth:getType()
  if (ethType == featureCfg.enum.ETH_TYPE.ip6) then ip6 = true
  elseif (ethType == featureCfg.enum.ETH_TYPE.ip4) then ip6 = false
  else
    packet:getEthernetPacket().payload.uint32[0] = payload
    return
  end
  local proto = nil
  if (ip6) then proto = packet:getIPPacket(false).ip6:getNextHeader()
  else proto = packet:getIPPacket().ip4:getProtocol() end
  
  if (proto == featureCfg.enum.PROTO.udp) then
    packet:getUdpPacket(not ip6).payload.uint32[0] = payload
  elseif (proto == featureCfg.enum.PROTO.tcp) then
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
  if (pkt.eth_type == featureCfg.enum.ETH_TYPE.ip6) then
    local ip6Pkt = packet:getIPPacket(false).ip6
    pkt.tos       = ip6Pkt:getTrafficClass()
    pkt.ttl       = ip6Pkt:getTTL()
    pkt.src_ip    = ip6Pkt:getSrcString()
    pkt.dst_ip    = ip6Pkt:getDstString()
    pkt.proto     = ip6Pkt:getNextHeader()
    pkt.proto_str = ip6Pkt:getNextHeaderString()
    curPkt = ip6Pkt
  elseif (pkt.eth_type == featureCfg.enum.ETH_TYPE.ip4) then
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
  if (pkt.proto == featureCfg.enum.PROTO.udp) then
    local udpPkt = packet:getUdpPacket()
    pkt.src_port = udpPkt.udp:getSrcPort()
    pkt.dst_port = udpPkt.udp:getDstPort()
    pkt.id       = udpPkt.payload.uint32[0]
    curPkt = udpPkt
  elseif (pkt.proto == featureCfg.enum.PROTO.tcp) then
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
function featureTxSlave(featureName, txDevs, ports)
  importSettings(featureName)
  local txQueues = {}
  local txCtrs = {}
  
  -- check which number of txDevs should be used
  local txDevNum = settings.txDevs
  if (txDevNum <= 0) then txDevNum = #txDevs end
  for i=1,txDevNum do
    txQueues[i] = txDevs[i]:getTxQueue(0) 
    txCtrs[i] = stats:newDevTxCounter(txDevs[i], "plain")
  end
  local txDump = io.open("../results/feature_" .. featureName .. "_tx.dump", "w")
  
  local txSteps = settings.txSteps
  if (txSteps <= 0) then txSteps = #txDevs end
  featureCfg.createPkt()
  local id = 0
  for n=1,txSteps do
    local ip6 = settings.ip6 ~= nil and settings.ip6 == true 
    local mempool = memory.createMemPool(function(buf)
        fillPacket(buf, settings.pktSize, featureCfg.pkt.PROTO, ip6)
      end) 
    local txBuf = mempool:bufArray(settings.bufSize)
    for i=1,settings.iterations do
      txBuf:alloc(settings.pktSize)
      for p, buf in ipairs(txBuf) do
        --local id = (n-1)*settings.batchSize + (i-1)*settings.bufSize + p
        id = id + 1
        setPayload(buf, id)
        txDump:write("Packet " .. p .. " / " .. tostring(settings.batchSize) .. " - " .. id .. " / " .. tostring(txSteps*settings.batchSize) .. " on dev " .. tostring(ports[n]) .. "\n")
        buf:dump(txDump)
      end
      if (featureCfg.pkt.PROTO == FeatureConfig.enum.PROTO.udp) then
        txBuf:offloadUdpChecksums(not ip6)
      elseif (featureCfg.pkt.PROTO == FeatureConfig.enum.PROTO.tcp) then
        txBuf:offloadTcpChecksums(not ip6)
      end
      txQueues[FeatureConfig.pkt.TX_DEV_ID]:send(txBuf)
    end
    local modifyPkt = settings.config.modifyPkt
    if (modifyPkt) then modifyPkt() end
  end   
  for i=1,txDevNum do
    txCtrs[i]:finalize()
  end 
  io.close(txDump)
end

-- Receives all packets and evaluates test conditions
function featureRxSlave(featureName, rxDevs, ports)
  importSettings(featureName)
  local mempool = memory.createMemPool(function(buf)
    fillPacket(buf, settings.pktSize)
  end)
  local rxBuf = mempool:bufArray()
  local rxQueues = {}
  
  local firstRxDev = settings.firstRxDev or 1
  local rxCtrs = {}
  for i=firstRxDev,#rxDevs do
    rxQueues[i] = rxDevs[i]:getRxQueue(0) 
    rxCtrs[i] = stats:newDevRxCounter(rxDevs[i], "plain")
  end
  local timeout = dpdk.getTime() + settings.timeout
  local rxPkts = {}
  local rxDump = io.open("../results/feature_" .. featureName .. "_rx.dump", "w")
  
  while dpdk.running() do
    for i=settings.firstRxDev,#rxDevs do
      local rx = rxQueues[i]:tryRecv(rxBuf, 0)
      for j=1,rx do
        local pkt = rxBuf[j]
        local recv = retrievePacket(pkt, i, ports)
        table.insert(rxPkts, recv)
        rxDump:write("Packet " .. recv.id .. " / " .. tostring(settings.config.evalCrit.desiredCtr*settings.batchSize) .. " (" .. tostring(settings.txSteps*settings.batchSize) .. ") on dev " .. ports[i] .. "\n")
        pkt:dump(rxDump)
      end
    end
    if (dpdk.getTime() > timeout) then break end
  end
  for i=settings.firstRxDev,#rxDevs do
    rxCtrs[i]:finalize()
  end
  io.close(rxDump)
  saveResult(featureName, evaluate(featureName, rxPkts, rxCtrs, ports))
end