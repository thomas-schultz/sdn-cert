--Benchmark config file

BenchmarkConfig = {}
BenchmarkConfig.__index = BenchmarkConfig

function BenchmarkConfig.new()
  return setmetatable({}, BenchmarkConfig)
end

BenchmarkConfig.IP = {
  parseIP = function(addr)
      local oct1,oct2,oct3,oct4 = addr:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
      return {oct1, oct2, oct3, oct4}
    end,
  incAndWrap = function(ip)
      ip[4] = ip[4] + 1
      for oct=4,1,-1 do
        if (ip[oct] > 255) then
          ip[oct] = 0
          ip[oct-1] = ip[oct-1] + 1
        else break end
      end
      if (ip[0]) then
        ip[0] = nil
        ip[4] = 0
      end
    end,
  getIP = function(ip)
      local addr = tostring(ip[1])
      for i=2,4 do addr = addr .. "." .. tostring(ip[i]) end
      return addr
    end,
}

return BenchmarkConfig