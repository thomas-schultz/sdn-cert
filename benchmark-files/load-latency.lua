local device = require "device"
local dpdk   = require "dpdk"
local filter = require "filter"
local hist   = require "histogram"
local memory = require "memory"
local stats  = require "stats"
local timer  = require "timer"
local ts     = require "timestamping"

-- set addresses here
local eth_Type  = { ip4 = 0x0800, ip6 = 0x86dd, arp = 0x0806, wol = 0x0842 }
local SRC_MAC   = "aa:bb:cc:dd:ee:ff"
local DST_MAC   = "ff:ff:ff:ff:ff:ff"
local SRC_IP    = "10.0.0.0"
local DST_IP    = "10.0.0.1"
local SRC_PORT  = 1234
local DST_PORT  = 1234


function master(testId, txPort, rxPort, duration, rate, numIP, size)
  if not tonumber(testId) or not tonumber(txPort) or not tonumber(rxPort) or not tonumber(duration) or
     not tonumber(size) or not tonumber(rate) or not tonumber(numIP) then
    print("usage: testId txDev rxDev duration size rate numIP")
    return
  end
  local txDev = device.config{
    port = txPort,
    rxQueues = 1,
    txQueues = 2,
  }
  local rxDev = device.config{
    port = rxPort,
    rxQueues = 2,
    txQueues = 2,
  }
  device.waitForLinks()
  txDev:getTxQueue(0):setRate(rate - (size + 4) * 8 / 1000)
  dpdk.launchLua("loadSlave", testId, txDev:getTxQueue(0), rxDev, size, numIP, duration, rate)
  dpdk.launchLua("timerSlave", testId, txDev:getTxQueue(1), rxDev:getRxQueue(1), size, numIP, duration)
  dpdk.waitForSlaves()
end

local function fillUdpPacket(buf, len)
  buf:getUdpPacket():fill{
    ethSrc = SRC_MAC,
    ethDst = DST_MAC,
    ip4Src = SRC_IP,
    ip4Dst = DST_IP,
    udpSrc = SRC_PORT,
    udpDst = DST_PORT,
    pktLength = len
  }
end

function nextSlave(queue, match)
  local size  = 60
  local count = 1
  local mempool = memory.createMemPool(function(buf)
    fillUdpPacket(buf, size)
  end)
  local bufs = mempool:bufArray(count)
  
  while dpdk.running() do
    bufs:alloc(size)
    for i, buf in ipairs(bufs) do
      local pkt = buf:getUdpPacket()
      pkt.eth:setType(eth_Type.wol)
    end
    bufs:offloadUdpChecksums()
    queue:send(bufs)
    break
  end
end

function loadSlave(id, queue, rxDev, size, numIP, duration, rate)
  local mempool = memory.createMemPool(function(buf)
    fillUdpPacket(buf, size)
  end)
  local bufs = mempool:bufArray()
  local counter = 0
  local txCtr = stats:newDevTxCounter(queue, "plain")
  local rxCtr = stats:newDevRxCounter(rxDev, "plain")
  local baseIP = parseIPAddress(DST_IP)
  local start = dpdk.getTime()
  local timeout = dpdk.getTime() + duration
    
  while dpdk.running() do
    bufs:alloc(size)
    for i, buf in ipairs(bufs) do
      local pkt = buf:getUdpPacket()
      pkt.ip4.dst:set(baseIP + counter)
      counter = incAndWrap(counter, numIP)
    end
    -- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
    bufs:offloadUdpChecksums()
    queue:send(bufs)
    txCtr:update()
    rxCtr:update()
    if dpdk.getTime() > timeout then break end
  end
  
  txCtr:finalize()
  rxCtr:finalize()
  local logFile = "../results/test_" .. id .. "_load.csv"
  local log = io.open(logFile, "w")
  local txStats = {n = select("#", txCtr:getStats()), txCtr:getStats()}
  local rxStats = {n = select("#", rxCtr:getStats()), rxCtr:getStats()}
  local stats = {mpps = 1, mbit = 2, wireMbit = 3, total = 4, totalBytes = 5}
  log:write("mpps.avg; mbit.avg; wireMbit.avg; total; totalBytes\n")
  log:write(txStats[stats.mpps].avg .. "; " .. txStats[stats.mbit].avg .. "; " .. txStats[stats.wireMbit].avg .. "; " .. txStats[stats.total] .. "; " .. txStats[stats.totalBytes] .. "\n")
  log:write(rxStats[stats.mpps].avg .. "; " .. rxStats[stats.mbit].avg .. "; " .. rxStats[stats.wireMbit].avg .. "; " .. rxStats[stats.total] .. "; " .. rxStats[stats.totalBytes] .. "\n")
  io.close(log)
  print("Saving throughput to '" .. logFile .. "'")
end

function timerSlave(id, txQueue, rxQueue, size, numIP, duration)
  rxQueue.dev:filterTimestamps(rxQueue)
  if size < 84 then
    printf("WARNING: packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
    size = 84
  end
  rxQueue.dev:filterTimestamps(rxQueue)
  local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
  local hist = hist:new()
  local start = dpdk.getTime()
  dpdk.sleepMillis(1000) -- ensure that the load task is running
  local counter = 0
  local rateLimit = timer:new(0.001)
  local baseIP = parseIPAddress(DST_IP)
  local timeout = dpdk.getTime() + duration
  
  while dpdk.running() do
    local time = dpdk.getTime()
    hist:update(timestamper:measureLatency(size, function(buf)
      fillUdpPacket(buf, size)
      local pkt = buf:getUdpPacket()
      pkt.ip4.dst:set(baseIP + counter)
      counter = incAndWrap(counter, numIP)
    end))
    rateLimit:wait()
    rateLimit:reset()
    if dpdk.getTime() > timeout then break end
  end
  dpdk.sleepMillis(300)
  hist:print()
  hist:save("../results/test_" .. id .. "_latency.csv")
end

