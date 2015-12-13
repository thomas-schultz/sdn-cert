-- general library for feature configuration

FeatureConfig = {}
FeatureConfig.__index = FeatureConfig

function FeatureConfig.new()
  return setmetatable({}, FeatureConfig)
end

-- counter type:
FeatureConfig.logicalOps = {
    -- packets have to be received on all devices
    all  = function(a, b) return not (a == nil and b == nil) and (a == nil or a) and (b == nil or b) end,
    -- packets have to be received on any devices
    any  = function(a, b) return a or (b ~= nil and b) end,
    -- packets have to be received only on a single devices 
    one  = function(a, b) return ((a or b) and not (a and b)) or false end,
  }
  
FeatureConfig.eval = function(ctrs, batch, threshold)
    return (math.abs(ctrs - batch) <= threshold)
  end

-- enums for common values
FeatureConfig.enum = {
    ETH_TYPE  = { ip4 = 0x0800, ip6 = 0x86dd, arp = 0x0806, wol = 0x0842 },
    PROTO     = { udp = 0x11, tcp = 0x06, icmp = 0x01, undef = nil },
    TOS       = { dft = 0x00, mod = 0x80 },
    TTL       = { max = 64, min = 1, zero = 0 },
  }
  
-- default settings
FeatureConfig.settings = {
    pktSize       = 80,       -- default packet size in bytes, without CRC
    bufSize       = 32,       -- number of packets in one buffer
    loops         = 1,        -- loop count, each is sending bufSize packets
    maxDeviation  = 0.05,     -- percentage of allowed deviation for received packets
    threshold     = 5,         -- lower bound for the maximum number of deviating packets
    learnTime     = 500,      -- time in milliseconds, where learning packets are generated and discarded by the receiver
    learnPkts     = 2,        -- number of packets, that will be generated for learning
    timeout       = 2,        -- timeout in seconds until the receiving loop is stopped
    txIterations  = 1,        -- number of sending steps, modifyPkt is called after each, nil means number of devices
    txDev         = 1,        -- number of sending devices
    firstRxDev    = 2,        -- first device for receiving
    ctrType       = "any",    -- counter type specified in logicalOps
    desiredCtr    = 1.0,      -- factor for received packet, applies to batch size (bufSize*loops)
  }

-- append given settings to default values    
FeatureConfig.config = function(settings)
    for k,v in pairs(settings) do FeatureConfig.settings[k] = v end
  end
 
-- overrides given settings concrete values    
FeatureConfig.set = function(key, value)
    settings[key] = value
  end

-- default packet
FeatureConfig.defaultPkt = {
    ETH_TYPE  = FeatureConfig.enum.ETH_TYPE.ip4,
    SRC_MAC   = "aa:00:00:00:00:a1",
    DST_MAC   = "ff:ff:ff:ff:ff:ff", 
    SRC_IP4   = "10.0.1.1",
    SRC_IP6   = "fc00:0000:0000:0000:0000:0000:0001:0001",
    DST_IP4   = "10.0.1.2",
    DST_IP6   = "fc00:0000:0000:0000:0000:0000:0001:0002",
    PROTO     = FeatureConfig.enum.PROTO.udp,
    SRC_PORT  = 1234, 
    DST_PORT  = 5678,
    TOS       = FeatureConfig.enum.TOS.dft,
    TTL       = FeatureConfig.enum.TTL.max,
  }

-- returns copy of the default packet
FeatureConfig.getDefaultPkt = function()
  return FeatureConfig.getPkt(FeatureConfig.defaultPkt)
end

-- returns copy of the given packet
FeatureConfig.getPkt = function(pkt)
  local _pkt = {}
  for k,v in pairs(pkt) do _pkt[k] = v end
  return _pkt
end

-- checks if packet is IPv6 
FeatureConfig.isIPv6 = function(pkt)
  return (pkt.ETH_TYPE == FeatureConfig.enum.ETH_TYPE.ip6)
end

-- modifies the given packet, by default none is changed
FeatureConfig.modifyPkt = function(pkt, iteration)
end

-- default packet classifier, all packets passes independent from their content
FeatureConfig.pktClassifier = {
    function(pkt) return true end,
  }

-- default evaluate function, success if the first counter has enough packets
FeatureConfig.evalCounters = function(ctrs, batch, threshold) 
    return (FeatureConfig.eval(ctrs[1], batch, threshold))
  end
  
return FeatureConfig