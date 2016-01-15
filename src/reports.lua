Reports = {}
Reports.__index = Reports

--------------------------------------------------------------------------------
--  class for generating the LaTeX reports
--------------------------------------------------------------------------------

Reports.allReports = {}
Reports.frontReport = 1

--- Adds a report to the list. The list has two points for adding new elements
-- Either at the end, or if front is specified to the priority position.
function Reports.addReport(doc, title, front)
  if (front == nil) then fron = false end
  local item = {
    file = string.replace(doc:getFile(), settings:getLocalPath() .. "/" .. global.results, ".") .. ".tex",
    title = title
  }
  if (front) then 
    table.insert(Reports.allReports, Reports.frontReport, item)
    Reports.frontReport = Reports.frontReport + 1
  else
    table.insert(Reports.allReports, item)
  end
end

--- Generates the single-test reports and the accumulated advanced reports
function Reports.generate(benchmark)
  for id,test in pairs(benchmark.testcases) do
    logger.printlog("Generating reports ( " .. id .. " / " .. #benchmark.testcases .. " ): " .. test:getName(true), nil, global.headline1)
    if (not test:isDisabled()) then test:createReport()
    elseif (settings:doSimulate()) then logger.print("skipping report, no data available") 
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
          if (not settings:doSimulate()) then
            Reports.generateCombined(benchmark, reports[currentParameter], currentParameter, data.ids)
          end
        end
      end
    end
    for par,report in pairs(reports) do
      report:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. currentTestName .. "/eval", "parameter_" .. par)
      report:generatePDF()
      Reports.addReport(report, "Advanced Report " .. currentTestName .. "-" .. par, true)
    end
  end
  if (not benchmark:checkExit()) then
    Reports.summarize()
  end 
  logger.printBar()
end

--- Generates the feature report.
function Reports.generateFeatureReport(featureList)
  local doc = TexDocument.create()
  local colorDef = TexText.create()
  colorDef:add("\\definecolor{darkgreen}{rgb}{0, 0.45, 0}")
  colorDef:add("\\definecolor{darkred}{rgb}{0.9, 0, 0}")
  doc:addElement(colorDef)
  local title = TexText.create()
  title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Summary Feature-Tests}", "\\end{LARGE}", "\\end{center}")
  local ofvers = TexText.create()
  title:add("\\begin{center}", "\\begin{huge}", "Version: " .. settings:getOFVersion(), "\\end{huge}", "\\end{center}")
  doc:addElement(ofvers)
  doc:addElement(title)
  local features = TexTable.create("|l|l|l|l|","ht")
  features:add("\\textbf{feature}", "\\textbf{type}", "\\textbf{version}", "\\textbf{status}")
  for i,feature in pairs(featureList) do
    features:add(feature:getName(true), feature:getState(), feature:getRequiredOFVersion(), feature:getTexStatus())
  end
  doc:addElement(features)
  doc:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/features/eval", "Feature-Tests")
  doc:generatePDF()
  Reports.addReport(doc, "Feature-Tests", true)
end

--- Creates a single test report from a testcase.
function Reports.createTestReport(testcase, error)
  local metric = require("metrics")
  local config = metric.config[testcase:getMetric()]
  if (not metric) then
    logger.err("Missing metric configuration in benchmark_config.lua")
    return
  end
  local data = config.getData(testcase)
  local plots = config.getPlots(testcase)

  local doc = TexDocument.create()
  local title = TexText.create()
  if (not error) then
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test " .. testcase:getId() .. ": " .. testcase:getName(true) .. "}", "\\end{LARGE}", "\\end{center}")
  else
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{FAILED - Test " .. testcase:getId() .. ": " .. testcase:getName(true) .. "}", "\\end{LARGE}", "\\end{center}")  
  end
  doc:addElement(title)
  doc:addElement(testcase:getParameterTable(config))
  for _,item in pairs(data) do
    doc:addElement(item)
  end
  for _,item in pairs(plots) do
    doc:addElement(item)
  end 
  doc:saveToFile(settings:getLocalPath() .. "/" .. global.results .. "/" .. testcase:getName(true) .. "/eval", testcase:getName())
  doc:generatePDF()
  Reports.addReport(doc, "Single Test " .. testcase:getId())
end

--- Creates an advanced report and adds it to the list of reports for
-- the current parameter.
function Reports.generateCombined(benchmark, doc, currentParameter, ids)
  local test = benchmark.testcases[ids[1]]
  local metric = require("metrics")
  local config = metric.config[test:getMetric()]
  local items = config.advanced(currentParameter, benchmark.testcases, ids) 
  
  local parameter = test:getParameterTable(config, currentParameter)
  parameter:add("involved tests", table.tostring(ids, ","), "IDs")
  doc:addElement(parameter) 
  for _,item in pairs(items) do
    doc:addElement(item)
  end
  doc:addClearPage()
end

--- Creates the full sumary report containing all existing reports.
function Reports.summarize()
  logger.printlog("Generating full report, may take a while", nil, global.headline1)
  local doc = TexDocument.create()
  doc:usePackage("standalone")
  doc:usePackage("hyperref")
  local pre = TexText.create()
  pre:add("\\tableofcontents")
  pre:add("\\renewcommand{\\chaptername}{}")
  pre:add("\\renewcommand{\\thechapter}{}")
  doc:addElement(pre)
  for _,report in pairs(Reports.allReports) do
    local item = TexText.create()
    item:add("\\chapter{" .. report.title .. "}")
    item:addCmd("\\input{" .. report.file .. "}")
    doc:addElement(item)
  end
  doc:saveToFile(settings:getLocalPath() .. "/" .. global.results, "Report")
  doc:generatePDF()
end

return Reports