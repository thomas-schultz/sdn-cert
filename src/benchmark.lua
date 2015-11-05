Benchmark = {}
Benchmark.__index = Benchmark

package.path = package.path .. ';' .. global.benchmarkFolder .. '/?.lua'
package.path = package.path .. ';' .. global.benchmarkFolder .. '/config/?.lua'

require "tex/document"

function Benchmark.create(config)
  local self = setmetatable({}, Benchmark)
  self.testcases = {}
  self.features = {}
  self.featureCount = 0
  self.config = config
  self:readConfig(config)
  return self
end

-- read in the benchmark configuration
function Benchmark:readConfig(config)
  if (settings.config.testfeature) then return end
  local fh = io.open(config)
  while true do
    local line = fh:read()
    if (not line) then break end
    line = string.trim(line)
    if (not (string.sub(line, 1,1) == global.ch_comment)) then
      if (#line > 0 and string.sub(line, 1,7) == "include") then
        local include = string.trim(string.sub(line, 8,-1))
        self:readConfig(include .. global.cfgFiletype)
      elseif (#line > 0) then
        local test = TestCase.create(line)
        table.insert(self.testcases, test)
        logger.debug("added testcase " .. line)
      end
    end
  end
  io.close(fh)
  if (self:checkExit()) then exit() end
end

function Benchmark:checkExit()
  if (#self.testcases == 0) then return true
  else return false end
end

function Benchmark:getFeatures()
  if (settings.isTestFeature()) then
    self.featureList = {}
    local feature = Feature.create(settings.getTestFeature())
    if feature:isDisabled() then return end
    self.features[settings.getTestFeature()] = feature
    self.featureCount = 1
    table.insert(self.featureList, 1, feature)        
    return
  end
  local list = settings.config.localPath .. "/" .. global.featureFolder .. "/" .. global.featureList
  local fh = io.open(list)
  if (not fh) then logger.printlog("Could not open feature list '" .. list .. "'", "ERR") return end
  self.featureList = {}
  self.featureCount = 0
  while true do
    local line = fh:read()
    if line == nil then break end
    if (not (string.sub(line, 1,1) == global.ch_comment) and string.len(line) > 0 ) then
      local feature = Feature.create(line)
      if (not feature:isDisabled()) then
        self.features[line] = feature
        self.featureCount = self.featureCount + 1
        table.insert(self.featureList, self.featureCount, feature)    
        logger.debug("added feature " .. line)    
      end
    end
  end
end

function Benchmark:exportFeatures()
  if (settings.config.skipfeature or settings.config.simulate) then return end
  local file = io.open(global.featureFile, "w")
  file:write("#Feature status\n#Last update: " .. logger.getTimestamp() .. "\n\n")
  local t = {}
  for name, feature in pairs(self.features) do
    table.insert(t,name)
  end
  table.sort(t)
  for i,name in pairs(t) do
    file:write(string.format("%-22s = %s\n", name, tostring(self.features[name]:isSupported())))
  end
  io.close(file)
end

function Benchmark:importFeatures()
  self:getFeatures()
  if (not localfileExists(global.featureFile)) then return end
  local fh = io.open(global.featureFile)
  while true do
    local line = fh:read()
    if line == nil then break end
    if ( not (string.sub(line, 1,1) == global.ch_comment) and string.len(line) > 0 ) then
      local split = string.find(line, global.ch_equal)
      if (split) then
        local name = string.trim(string.sub(line, 1, split-1))
        local state = string.trim(string.sub(line, split+1, -1))
        local feature = self.features[name]
        if (feature and state == "true") then feature.supported = true end
        logger.debug("imported feature " .. name .. " as " .. state)   
      end
    end
  end
  io.close(fh)
  if (not settings.config.testfeature and not settings.config.skipfeature) then printBar() end
end

function Benchmark:isFeatureSupported(name)
  if (not self.features[name]) then
    logger.printlog("Feature '" .. name .. "' disabled or not found, check log", "WARN")
    return false
  end
  return self.features[name]:isSupported()
end

function Benchmark:testFeatures()
  if settings.config.skipfeature then
    self:importFeatures() 
    return
  end
  self:getFeatures()
  if (self.featureCount == 0) then
    logger.printlog("No features to test")
  end
  for i,feature in pairs(self.featureList) do
    logger.printlog("Testing feature ( " .. i .. " / " .. self.featureCount .. " ): " .. feature:getName(true), 0, global.headline1)
    feature:runTest()
    if (not settings.config.simulate) then logger.print(feature:getStatus(), 1) end
  end
  logger.log("Step complete")
  if (settings.config.testfeature) then
    logger.printBar()
    self:sumFeatures()
    if (self.features[settings.config.testfeature] ~= nil) then
      local state = self.features[settings.config.testfeature]:isSupported()
      self:importFeatures()
      self.features[settings.config.testfeature].supported = state
    end
    self:exportFeatures()
    exit()
  end
  self:exportFeatures()
  logger.printBar()
end

function Benchmark:prepare()
  if (settings.config.testfeature) then return end
  local testcases = {}
  for id,test in pairs(self.testcases) do
    logger.printlog("Preparing test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), global.headline1)
    test:checkFeatures(self)
    if (not test:isDisabled() or settings.config.simulate) then
      local files = test:getLoadGenFiles()
      for i,file in pairs(files) do
        logger.print("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")", 1, global.headline2)
        local cmd = SCPCommand.create()
        cmd:switchCopyTo(settings:isLocal(), settings.config.localPath .. "/" .. global.benchmarkFolder .. "/" .. file, settings:get(global.loadgenWd) .. "/" .. global.scripts)
        cmd:execute(settings.config.verbose)
      end
      local id = #testcases + 1
      test:setId(id)
      table.insert(testcases, id, test)
    end
    logger.log("done")
  end
  self.testcases = testcases
  logger.log("Step complete")
  logger.printBar()
end

function Benchmark:run()
  if (settings.config.testfeature) then return end
  if (self:checkExit()) then logger.printlog("No test left") end
  for id,test in pairs(self.testcases) do
    logger.printlog("Running test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), global.headline1)
    if (settings.config.verbose) then test:print() end
    
    -- configure open-flow device
    logger.print("Configuring OpenFlow device (~" .. global.timeout .. " sec)", 1, global.headline2)
    local path = settings.config.localPath .. "/" .. global.results .. "/" .. test:getName()
    local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort])
    ofDev:reset()
    local flowData = ofDev:getFlowData(test)
    ofDev:createAllFiles(flowData, path)
    ofDev:installAllFiles(path, "_ovs.output")
    ofDev:dumpAll(path .. ".before")
    if (not settings.config.simulate) then sleep(global.timeout) end   
    test:export(path .. "_parameter.csv")
    
    -- start loadgen
    local duration = test:getDuration() or "?"
    duration = " (measuring for " .. duration .. " sec)"
    logger.print("Starting measurement" .. duration, 1, global.headline2)
    local lgDump = io.open(path .. "_loadgen.output", "w")
    local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
    cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
    cmd:addCommand("./" .. test:getLoadGen() .. " " .. test:getLgArgs())
    if (settings:isVerbose()) then cmd:print() end
    lgDump:write(cmd:execute(settings:isVerbose()))
    if (not Settings:doSimulate()) then
      ofDev:dumpAll(path .. ".after")
    end
    io.close(lgDump)
    logger.print("Collecting results", 1, global.headline2)
    local cmd = SCPCommand.create()
    cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .."/test_" .. id .. "_*.csv", settings.config.localPath .. "/" .. global.results)
    cmd:execute(settings.config.verbose)
    logger.log("done")
  end
  logger.log("Step complete")
  logger.printBar()
end

function Benchmark:sumFeatures()
  if (self.featureCount == 0) then
    logger.print("No features tested")
  else
    local compliance = true;
    for i,feature in pairs(self.featureList) do
      logger.print(string.format("Feature:   ".. ColorCode.white .. "%-24s" .. ColorCode.normal .. "%-24s %s", feature:getName(true), feature:getState()..",".. feature:getRequiredOFVersion(), feature:getStatus()))
      compliance = compliance and (feature:getState() == global.featureState.optional or (feature:isSupported() and feature:getState() == global.featureState.required)) 
    end
    if (not settings.config.testfeature) then
      if (compliance) then logger.printlog("\nTestdevice has passed all required tests for " .. settings.config[global.ofVersion], "lgreen")
      else logger.printlog("\nTestdevice is not compliant with " .. settings.config[global.ofVersion], "lred") end
    end
  end
  local doc = TexDocument.create()
  local title = TexText.create()
  title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Summary Feature-Tests}", "\\end{LARGE}", "\\end{center}")
  local ofvers = TexText.create()
  title:add("\\begin{center}", "\\begin{huge}", "Version: " .. settings:getOFVersion(), "\\end{huge}", "\\end{center}")
  doc:addElement(ofvers)
  doc:addElement(title)
  local features = TexTable.create("|l|l|l|l|","ht")
  features:add("\\textbf{feature}", "\\textbf{type}", "\\textbf{version}", "\\textbf{status}")
  for i,feature in pairs(self.featureList) do
    features:add(feature:getName(true), feature:getState(), feature:getRequiredOFVersion(), feature:getTexStatus())
  end
  doc:addElement(features)
  doc:generatePDF("Feature-Tests")
  logger.printBar()
end

function Benchmark:generateTestDB()
  local db = {}
  local paramaterList = {}
  for id,test in pairs(self.testcases) do
    local testName = test:getName(true)
    db[testName] = db[testName] or {}
    local case = {}
    local parameters = test:getParameterList()
    case.parameters = parameters
    case.id = test:getId()
    table.insert(db[testName],case)
    for name,value in pairs(parameters) do
      if (name ~= "name") then paramaterList[name] = true end
    end
  end
  return paramaterList, db
end

function Benchmark:generateReports()
  for id,test in pairs(self.testcases) do
    test:setId(id)
    logger.printlog("Generating reports ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), 0, global.headline1)
    test:createReport()
  end

  local paramaterList,globalDB = self:generateTestDB()
  for currentTestName,testDB in pairs(globalDB) do
    local reports = {}
    for currentParameter,_ in pairs(paramaterList) do
      local set = {}
      for _,test in pairs(testDB) do
        local conf = ""
        for parameter,value in pairs(test.parameters) do
        if (parameter ~= currentParameter) then
          conf = conf .. parameter .. "=" .. value .. "," end    
        end
        --print(currentParameter, conf)
        if (not set[conf]) then set[conf] = {num = 0, ids = {}} end
        set[conf].num = set[conf].num + 1
        table.insert(set[conf].ids, test.id)
      end
      for conf,data in pairs(set) do
        if (data.num > 1) then
          --print(data.num, conf)
          if (not reports[currentParameter]) then
            logger.printlog("Generating advanced report for " .. currentTestName .. "/" .. currentParameter, 0, global.headline1)
            reports[currentParameter] = TexDocument.create()
            local title = TexText.create()
            title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test: " .. currentTestName .. "}", "\\end{LARGE}", "\\end{center}")
            reports[currentParameter]:addElement(title)
            local subtitle = TexText.create()
            subtitle:add("\\begin{center}", "\\begin{huge}", "parameter: " .. currentParameter, "\\end{huge}", "\\end{center}")
            reports[currentParameter]:addElement(subtitle)
          end
          self:generateAdvancedReport(reports[currentParameter], currentTestName, currentParameter, data.ids)
        end
      end
    end
    for par,report in pairs(reports) do
      report:saveToFile(currentTestName .. "_" .. par)
      report:generatePDF()
    end
  end  
  logger.printBar()
end

function Benchmark:generateAdvancedReport(doc, name, currentParameter, ids)
  local test = self.testcases[ids[1]]
  local config = require("benchmark_config")
  local metric = config.metric[test.config.metric]
  local items = metric.advanced(currentParameter, self.testcases, ids) 
  
  local parameter = TexTable.create("|l|r|", "ht")
  for k,v in pairs(test.parameters) do
    if (k ~= "name" and k ~= currentParameter) then parameter:add(k, v) end
  end
  parameter:add("involved tests", table.tostring(ids, ","))
  doc:addElement(parameter)  
  for _,item in pairs(items) do
    doc:addElement(item)
  end
end

function Benchmark:listTestCases()
  if (#self.testcases > 0 ) then logger.printBar() logger.print("Benchmark config:") end
  for id,test in pairs(self.testcases) do
    test:print()
  end
end
