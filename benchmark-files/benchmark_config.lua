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

BenchmarkConfig.labels = {
  rate = {
      x = "offered load in [mbit]",
    },
  pktsize = {
      x = "packet size in [bytes]",
    },
  numIP = {
      x = "number of different IPs",
    },
  default = {
      y = "archieved load in [mbit]",
    },
}

BenchmarkConfig.metric = {
  ["load-latency"] = {
    output = {"_load_rx.csv", "_load_tx.csv", "_latency.csv"},
    getData = function(test)
        local latency = FileContent.create("latency")
        latency:addCsvFile(settings.config.localPath .. "/" .. global.results .. "/test_" .. test:getId() .. "_latency.csv")
        local rx = FileContent.create("rx")
        rx:addCsvLine("0,0,0,0,0")
        rx:addCsvFile(settings.config.localPath .. "/" .. global.results .. "/test_" .. test:getId() .. "_load_rx.csv", true)
        rx:addCsvLine(tonumber(test:getDuration())+1 .. ",0,0,0,0")
        local tx = FileContent.create("tx")
        tx:addCsvLine("0,0,0,0,0")
        tx:addCsvFile(settings.config.localPath .. "/" .. global.results .. "/test_" .. test:getId() .. "_load_tx.csv", true)
        tx:addCsvLine(tonumber(test:getDuration())+1 .. ",0,0,0,0")
        return {latency, rx, tx} 
    end,
    getPlots = function(test)
        local throuh = TexFigure.create("ht")
        throuh:add(TexBlocks.mppsGraph("x index={0}, y index={2}", "throughput graph", "fig:throughput"))
        local hist = TexFigure.create("ht")
        hist:add(TexBlocks.histogram("latency in [ns]", "occurrence", "latency.csv", "latency histogram", "fig:latency"))
        return {throuh, hist}
    end,
    advanced = function(parameter, testcases, ids)
        local parMin,parMax
        local stats
        local rx = FileContent.create("rx")
        for _,id in pairs(ids) do
          local test = testcases[id]
          local par = test:getParameterList()[parameter]
          local data = csv.parseCsv(settings.config.localPath .. "/" .. global.results .. "/test_" .. id .. "_load_rx.csv")
          local stats = csv.getStats(data, true)
          if (not stats or not stats[4]) then stats = {[4] = {min = 0, avg = 0, max = 0}} end
          local line = ("%d;%.5f;%.5f;%.5f"):format(par, stats[4].min, stats[4].avg, stats[4].max)
          line = string.replaceAll(line, ",", ".")
          rx:addCsvLine(string.replaceAll(line, ";", ","))
        end
        local throuh = TexFigure.create("ht")
        local label = BenchmarkConfig.labels[parameter]
        if (not label) then
          label = BenchmarkConfig.labels.default
          label.x = parameter
        end
        if (not label.y) then label.y = BenchmarkConfig.labels.default.y end
        throuh:add(TexBlocks.throughput(label, 1,2,3))
        return {rx, throuh}
    end
  }
}

return BenchmarkConfig