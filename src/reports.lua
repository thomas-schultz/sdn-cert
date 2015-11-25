Reports = {}
Reports.__index = Reports


function Reports.generate(benchmark)
  for id,test in pairs(benchmark.testcases) do
    logger.printlog("Generating reports ( " .. id .. " / " .. #benchmark.testcases .. " ): " .. test:getName(true), nil, global.headline1)
    if (not test:isDisabled()) then test:createReport()
    else logger.warn("Test failed, skipping report") end
  end

  local globalDB = benchmark:generateTestDB()
  for currentTestName,testDB in pairs(globalDB) do
    -- iterate and create one report over every testname
    local reports = {} 
    for currentParameter,_ in pairs(globalDB[currentTestName].paramaterList) do
      -- iterate over all parameters of the current test
      local set = {}
      for id,testParameter in pairs(testDB.testParameter) do
        -- create configuration key, containing all other parameters
        local conf = ""
        for parameter,value in pairs(testParameter) do
        if (parameter ~= currentParameter) then
          conf = conf .. parameter .. "=" .. value .. "," end    
        end
        logger.debug("processing " .. currentParameter .. " with conf-key: " .. conf)
        -- count all test with the same conf-key
        if (not set[conf]) then set[conf] = {num = 0, ids = {}} end
        set[conf].num = set[conf].num + 1
        -- insert current test id to the list
        table.insert(set[conf].ids, id)
      end
      for conf,data in pairs(set) do
        if (data.num > 1) then
          logger.debug(conf .. " #:" .. data.num)
          if (not reports[currentParameter]) then
            logger.printlog("Generating advanced report for " .. currentTestName .. "/" .. currentParameter, nil, global.headline1)
            reports[currentParameter] = TexDocument.create()
            local title = TexText.create()
            title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test: " .. currentTestName .. "}", "\\end{LARGE}", "\\end{center}")
            reports[currentParameter]:addElement(title)
            local subtitle = TexText.create()
            subtitle:add("\\begin{center}", "\\begin{huge}", "parameter: " .. currentParameter, "\\end{huge}", "\\end{center}")
            reports[currentParameter]:addElement(subtitle)
          end
          Reports.generateCombined(benchmark, reports[currentParameter], currentTestName, currentParameter, data.ids)
        end
      end
    end
    for par,report in pairs(reports) do
      report:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. currentTestName .. "/eval", "parameter_" .. par)
      report:generatePDF()
    end
  end  
  logger.printBar()
end

function Reports.generateCombined(benchmark, doc, name, currentParameter, ids)
  local test = benchmark.testcases[ids[1]]
  local config = require("benchmark_config")
  local metric = config.metric[test.config.metric]
  local items = metric.advanced(currentParameter, benchmark.testcases, ids) 
  
  local parameter = test:getParameterTable(metric, name)
  parameter:add("involved tests", table.tostring(ids, ","), "IDs")
  doc:addElement(parameter) 
  for _,item in pairs(items) do
    doc:addElement(item)
  end
  doc:addClearPage()
end