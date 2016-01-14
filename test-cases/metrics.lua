-- Metric config file

Metrics = {}

Metrics.labels = {
  rate = {
      x = "offered load in [Mbps]",
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
      y = "achieved load in [Mbps]",
    },
}

Metrics.config = {
  ["load-latency"] = {
    output = {"_load_rx.csv", "_load_tx.csv", "_latency.csv"},
    units = {
      rate = "Mbps",
      duration = "sec",
      numip = "",
      pktsize = "Bytes (+4B CRC)",      
    },
    getData = function(test)
        local latency = FileContent.create("latency")
        local hist = Statistic.readHistogram(test:getOutputPath() .. "test_" .. test:getId() .. "_latency.csv", 2048)
        latency:addCsvData(hist)
        local rx = FileContent.create("rx")
        rx:addCsvFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_rx.csv", false)
        local tx = FileContent.create("tx")
        tx:addCsvFile(test:getOutputPath() .. "test_" .. test:getId() .. "_load_tx.csv", false)
        return {latency, rx, tx} 
    end,
    getPlots = function(test)
        local plots = {}
        local mpps = TexFigure.create("ht")
        mpps:add(Graphs.mppsGraph("x=time, y=mpps", "rx.csv", "tx.csv"))
        local mbps = TexFigure.create("ht")
        mbps:add(Graphs.mbpsGraph("x=time, y=mbit", "rx.csv", "tx.csv"))
        local loss = TexFigure.create("ht")
        -- TODO get total and los values from csv files
        --loss:add(Graphs.pktLoss(0, 0))
        local hist = TexFigure.create("ht")
        hist:add(Graphs.histogram({x="latency in [$\\mu$s]", y="occurrence"}, "latency.csv"))
        return {mpps, mbps, hist}
    end,
    advanced = function(parameter, testcases, ids)
        local items = {}
        local isNumber = true
        local data = {}
        for _,id in pairs(ids) do
          local test = testcases[id]
          local par = test:getParameterList()[parameter]
          -- if par is a number, store data under the number, else use string
          par = Float.tonumber(par) or par
          data[par] = CSV.parseAndCropCSV(test:getOutputPath() .. "test_" .. id .. "_load_rx.csv", 1, true)
          table.insert(items, par)
          isNumber = isNumber and Float.tonumber(par)
        end
        table.sort(items)
        local rx = FileContent.create("rx")
        rx:addCsvLine("parameter, min, low, med, high, max, avg")
        for _,par in pairs(items) do
          -- get data, cropping first and last line, use percentiles 10% and 90% 
          local stats = CSV.getStats(CSV.transpose(data[par], 10, 90))
          local row = 4 -- select Mbps values
          if (stats[row].num > 0) then
            local line = ("%s;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f"):format(par, stats[row].min, stats[row].lowP, stats[row].median, stats[row].highP, stats[row].max, stats[row].avg)
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
          throughput:add(Graphs.throughputStats(label, "rx.csv"))
        else
          throughput:add(Graphs.throughputBoxplot(label, "rx.csv", #items))
        end
        return {rx, throughput}
    end
  }
}

return Metrics