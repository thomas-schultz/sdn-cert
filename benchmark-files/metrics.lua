-- Metric config file

Metrics = {}

Metrics.labels = {
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

Metrics.config = {
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
        local items = {}
        local isNumber = true
        local data = {}
        for _,id in pairs(ids) do
          local test = testcases[id]
          local par = test:getParameterList()[parameter]
          -- if par is a number, store data under the number, else use string
          par = float.tonumber(par) or par
          data[par] = csv.parseAndCropCsv(test:getOutputPath() .. "test_" .. id .. "_load_rx.csv", 0, false)
          table.insert(items, par)
          isNumber = isNumber and float.tonumber(par)
        end
        table.sort(items)
        local rx = FileContent.create("rx")
        rx:addCsvLine("parameter, min, avg, max")
        for _,par in pairs(items) do
          local stats = csv.getStats(data[par], 1)
          local row = 4 -- select mbit row
          if (stats[row].num > 0) then
            local line = ("%s;%.5f;%.5f;%.5f"):format(par, stats[row].min, stats[row].avg, stats[row].max)
            line = string.replaceAll(line, ",", ".")
            rx:addCsvLine(string.replaceAll(line, ";", ","))
          end
        end
        
        local throughput = TexFigure.create("ht")
        local label = Metrics.labels[parameter]
        if (not label) then
          label = Metrics.labels.load
          label.x = parameter
        end
        if (not label.y) then label.y = Metrics.labels.load.y end
        if (isNumber) then
          throughput:add(TexBlocks.throughputStats(label, "rx.csv"))
        else
          throughput:add(TexBlocks.throughputStatsBars(label, "rx.csv"))
        end
        return {rx, throughput}
    end
  }
}

return Metrics