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
  filter = {
      x = "filter options",
    },
  load = {
      y = "achieved load in [mbit]",
    },
}

BenchmarkConfig.metric = {
  ["load-latency"] = {
    output = {"_load_rx.csv", "_load_tx.csv", "_latency.csv"},
    units = {
      rate = "MBit",
      duration = "sec",
      numip = "",
      pktsize = "Bytes (+4B CRC)",      
    },
    getData = function(test)
        local latency = FileContent.create("latency")
        latency:addCsvFile(test:getOutputPath() .. "test_" .. test:getId() .. "_latency.csv")
        local rx = FileContent.create("rx")
        rx:addCsvFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx.csv", false)
        local tx = FileContent.create("tx")
        tx:addCsvFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx.csv", false)
        return {latency, rx, tx} 
    end,
    getPlots = function(test)
        local plots = {}
        local mpps = TexFigure.create("ht")
        mpps:add(TexBlocks.mppsGraph("x=time, y=mpps", "rx.csv", "tx.csv"))
        local mbit = TexFigure.create("ht")
        mbit:add(TexBlocks.mbitGraph("x=time, y=mbit", "rx.csv", "tx.csv"))
        local loss = TexFigure.create("ht")
        -- TODO get total and los values from csv files
        --loss:add(TexBlocks.pktLoss(0, 0))
        local hist = TexFigure.create("ht")
        hist:add(TexBlocks.histogram({x="latency in [ns]", y="occurrence"}, "latency.csv"))
        return {mpps, mbit, hist}
    end,
    advanced = function(parameter, testcases, ids)
        local entries = {}
        local isNumber = true
        local data = {}
        for _,id in pairs(ids) do
          local test = testcases[id]
          local par = test:getParameterList()[parameter]
          -- if par is a number, store data under the number, else use string
          par = tonumber(par) or par
          data[par] = csv.parseAndCropCsv(test:getOutputPath() .. "test_" .. id .. "_load_rx.csv", 1, false)
          table.insert(entries, par)
          isNumber = isNumber and tonumber(par)
        end
        table.sort(entries)
        local rx = FileContent.create("rx")
        rx:addCsvLine("parameter, min, avg, max")
        for _,par in pairs(entries) do
          local stats = csv.getStats(data[par], true)
          if (not stats or not stats[4]) then stats = {[4] = {min = 0, avg = 0, max = 0}} end
          local line = ("%s;%.5f;%.5f;%.5f"):format(par, stats[4].min, stats[4].avg, stats[4].max)
          line = string.replaceAll(line, ",", ".")
          rx:addCsvLine(string.replaceAll(line, ";", ","))
        end
        
        local throughput = TexFigure.create("ht")
        local label = BenchmarkConfig.labels[parameter]
        if (not label) then
          label = BenchmarkConfig.labels.load
          label.x = parameter
        end
        if (not label.y) then label.y = BenchmarkConfig.labels.load.y end
        if (isNumber) then
          throughput:add(TexBlocks.throughputStats(label, "rx.csv"))
        else
          throughput:add(TexBlocks.throughputStatsBars(label, "rx.csv"))
        end
        return {rx, throughput}
    end
  }
}

return BenchmarkConfig