--- This script implements a simple QoS test by generating two flows and measuring their latencies.
local mg		= require "dpdk" -- TODO: rename dpdk module to "moongen"
local memory	= require "memory"
local device	= require "device"
local ts		= require "timestamping"
local filter	= require "filter"
local stats		= require "stats"
local hist		= require "histogram"
local timer		= require "timer"
local log		= require "log"

-- define packet here
local PACKET = {
  eth_Type  = { ip4 = 0x0800, ip6 = 0x86dd, arp = 0x0806, wol = 0x0842 },
  SRC_MAC   = "aa:bb:cc:dd:ee:ff",
  DST_MAC   = "ff:ff:ff:ff:ff:ff",
  SRC_IP    = "10.0.0.0",
  DST_IP    = "10.0.0.0",
  SRC_PORT  = 1234,
  DST_PORT  = 1234,
}

function master(testId, txPort, rxPort, duration, rate, numIP, size)
  if not tonumber(testId) or not tonumber(txPort) or not tonumber(rxPort) or not tonumber(duration) or
     not tonumber(size) or not tonumber(rate) or not tonumber(numIP) then
    print("usage: testId txDev rxDev duration size rate numIP")
    return
  end
  if (size < 60) then
    log:warn("Requested packet size below 64 Bytes")
    return
  end
	-- 2 tx queues: traffic, and timestamped packets
	-- 2 rx queues: traffic and timestamped packets
	txDev = device.config{ port = txPort, rxQueues = 1, txQueues = 2}
	rxDev = device.config{ port = rxPort, rxQueues = 2 }

	device.waitForLinks()
	txDev:getTxQueue(0):setRate(rate)
	-- create traffic
	mg.launchLua("loadSlave", testId, txDev:getTxQueue(0), size, numIP, duration, rate)
	-- count the incoming packets
	mg.launchLua("counterSlave", testId, rxDev:getRxQueue(0), duration)
	-- measure latency from a second queue
	mg.launchLua("timerSlave", testId, txDev:getTxQueue(1), rxDev:getRxQueue(1), size, numIP, duration)
	-- wait until all tasks are finished
	mg.waitForSlaves()
end

local function fillUdpPacket(buf, len)
  buf:getUdpPacket():fill{
    ethSrc = PACKET.SRC_MAC,
    ethDst = PACKET.DST_MAC,
    ip4Src = PACKET.SRC_IP,
    ip4Dst = PACKET.DST_IP,
    udpSrc = PACKET.SRC_PORT,
    udpDst = PACKET.DST_PORT,
    pktLength = len
  }
end

function loadSlave(id, queue, size, numIP, duration, rate)
	mg.sleepMillis(100) -- wait a few milliseconds to ensure that the rx thread is running
	local mempool = memory.createMemPool(function(buf)
    fillUdpPacket(buf, size)
  end)

  local txDump = "../results/test_" .. id .. "_load_tx.csv"
	local txCtr = stats:newDevTxCounter(queue, "CSV", txDump)
	local baseIP = parseIPAddress(PACKET.DST_IP)
	local timeout = mg.getTime() + duration

	local bufs = mempool:bufArray()
	while mg.running() do
		-- allocate buffers from the mem pool and store them in this array
		bufs:alloc(size)
		for _, buf in ipairs(bufs) do
			local pkt = buf:getUdpPacket()
			pkt.ip4.dst:set(baseIP + math.random(numIP) - 1)
		end
		-- send packets
		bufs:offloadUdpChecksums()
		queue:send(bufs)
		txCtr:update()
		if mg.getTime() > timeout then break end
	end
	txCtr:update()
	txCtr:finalize()
	log:info("Saving txCounter to '" .. txDump .. "'")
end

function counterSlave(id, queue, duration)
	local bufs = memory.bufArray()
	local rxDump = "../results/test_" .. id .. "_load_rx.csv"
	local rxCtr = stats:newDevRxCounter(queue, "CSV", rxDump)
	local timeout = mg.getTime() + duration + 1
	while mg.running() do
		local rx = queue:tryRecv(bufs, 0)
		bufs:freeAll()
		rxCtr:update()
		if mg.getTime() > timeout then break end
	end
	rxCtr:update()
	rxCtr:finalize()
	log:info("Saving rxCounter to '" .. rxDump .. "'")
end


function timerSlave(id, txQueue, rxQueue, size, numIP, duration)
	local txDev = txQueue.dev
	local rxDev = rxQueue.dev
	rxDev:filterTimestamps(rxQueue)
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist()
	-- wait one second, otherwise we might start timestamping before the load is applied
	mg.sleepMillis(1000)
	local baseIP = parseIPAddress(PACKET.DST_IP)
	local rateLimit = timer:new(0.001)
	local timeout = mg.getTime() + duration
	
	while mg.running() do
		local latency = timestamper:measureLatency(size, function(buf)
		  fillUdpPacket(buf, size)
			local pkt = buf:getUdpPacket()
			pkt.ip4.dst:set(baseIP + math.random(numIP) - 1)
		end)
		hist:update(latency)
		rateLimit:wait()
		rateLimit:reset()
		if mg.getTime() > timeout then break end
	end
	mg.sleepMillis(100) -- to prevent overlapping stdout
	hist:print()
  hist:save("../results/test_" .. id .. "_latency.csv")
end

