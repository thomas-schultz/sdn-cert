Benchmark = {}
Benchmark.__index = Benchmark


function Benchmark.create(config)
  local self = setmetatable({}, Benchmark)
  self.testcases = {}
  self.features = {}
  self.featureList = global.featureList
  self.feature_count = 0
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
        log_debug("added testcase " .. line)
      end
    end
  end
  io.close(fh)
  if (self:checkExit()) then exit() end
end

function Benchmark:checkExit()
  if #self.testcases == 0 then return true
  else return false end
end

function Benchmark:getFeatures()
  if (settings.isTestFeature()) then
    self.featureList = {}
    local feature = Feature.create(settings.getTestFeature())
    if feature:isDisabled() then return end
    self.features[settings.getTestFeature()] = feature
    self.feature_count = 1
    table.insert(self.featureList, 1, feature)        
    return
  end
  local list = settings.config.localPath .. "/" .. global.featureFolder .. "/" .. self.featureList
  local fh = io.open(list)
  if (not fh) then printlog_err("Could not open feature list '" .. list .. "'") return end
  self.featureList = {}
  self.feature_count = 0
  while true do
    local line = fh:read()
    if line == nil then break end
    if (not (string.sub(line, 1,1) == global.ch_comment) and string.len(line) > 0 ) then
      local feature = Feature.create(line)
      if (not feature:isDisabled()) then
        self.features[line] = feature
        self.feature_count = self.feature_count + 1
        table.insert(self.featureList, self.feature_count, feature)    
        log_debug("added feature " .. line)    
      end
    end
  end
end

function Benchmark:exportFeatures()
  if (settings.config.skipfeature or settings.config.simulate) then return end
  local file = io.open(global.featureFile, "w")
  file:write("#Feature status\n#Last update: " .. get_timestamp() .. "\n\n")
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
  self.featureList = {}
  self.feature_count = 0
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
        local feature = Feature.create(name)
        if (state == "true") then feature.supported = true end
        self.features[name] = feature    
        self.feature_count = self.feature_count + 1
        table.insert(self.featureList, self.feature_count, feature)
        log_debug("imported feature " .. name .. " as " .. state)   
      end
    end
  end
  io.close(fh)
  if (not settings.config.testfeature and not settings.config.skipfeature) then printBar() end
end

function Benchmark:isFeatureSupported(name)
  if not self.features[name] then
    printlog_warn("Feature disabled or not found, check log")
    return false
  end
  return self.features[name]:isSupported()
end

function Benchmark:cleanUp()
  printBar()
  printlog("Cleaning up testing system", global.headline1)
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd))
  cmd:addCommand("mkdir -p " .. global.results)
  cmd:addCommand("rm -f " .. global.results .. "/*")
  cmd:addCommand("mkdir -p " .. global.scripts)
  cmd:addCommand("rm -f " .. global.scripts .. "/*")
  cmd:execute()
  local cmd = CommandLine.create()
  cmd:addCommand("mkdir -p " .. settings.config.localPath .. "/" .. global.results)
  cmd:addCommand("rm -f " .. settings.config.localPath .. "/" .. global.results .. "/*")
  cmd:execute(settings.config.verbose)
  local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort])
  ofDev:reset()
  log("Step complete")
  printBar()
end

function Benchmark:testFeatures()
  if settings.config.skipfeature then
    self:importFeatures() 
    return
  end
  self:getFeatures()
  if self.feature_count == 0 then
    printlog("No features to test")
  end
  for i,feature in pairs(self.featureList) do
    printlog("Testing feature ( " .. i .. " / " .. self.feature_count .. " ): " .. feature:getName(true), global.headline1)
    feature:runTest()
    if (not settings.config.simulate) then showIndent(feature:getStatus(), 1) end
  end
  log("Step complete")
  if (settings.config.testfeature) then
    printBar()
    self:summary(true)
    if (self.features[settings.config.testfeature] ~= nil) then
      local state = self.features[settings.config.testfeature]:isSupported()
      self:importFeatures()
      self.features[settings.config.testfeature].supported = state
    end
    self:exportFeatures()
    exit()
  end
  self:exportFeatures()
  printBar()
end

function Benchmark:prepare()
  if (settings.config.testfeature) then return end
  local testcases = {}
  for id,test in pairs(self.testcases) do
    printlog("Preparing test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), global.headline1)
    test:checkFeatures(self)
    if (not test:isDisabled() or settings.config.simulate) then
      local files = test:getLoadGenFiles()
      for i,file in pairs(files) do
        showIndent("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")", 1)
        local cmd = SCPCommand.create()
        cmd:switchCopyTo(settings:isLocal(), settings.config.localPath .. "/" .. global.benchmarkFolder .. "/" .. file, settings:get(global.loadgenWd) .. "/" .. global.scripts)
        cmd:execute(settings.config.verbose)
      end
      table.insert(testcases, test)
    end
    log("done")
  end
  self.testcases = testcases
  log("Step complete")
  printBar()
end

function Benchmark:run()
  if (settings.config.testfeature) then return end
  if (self:checkExit()) then printlog("No test left") end
  for id,test in pairs(self.testcases) do
    printlog("Running test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), global.headline1)
    test:setId(id)
    if (settings.config.verbose) then test:print() end

    -- configure open-flow device
    showIndent("Configuring OpenFlow device (~" .. global.timeout .. " sec)", 1, global.headline2)
    local path = settings.config.localPath .. "/" .. global.results .. "/" .. test:getName()
    local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort])
    ofDev:reset()
    local flowData = ofDev:getFlowData(test)
    ofDev:createAllFiles(flowData, path)
    ofDev:installAllFiles(path, "_ovs.output")
    ofDev:dumpAll(path .. ".before")
    if (not settings.config.simulate) then sleep(global.timeout) end
    
    -- start loadgen
    print("ID: " .. test:getId())
    local duration = test:getDuration() or "?"
    duration = " (measuring for " .. duration .. " sec)"
    showIndent("Starting measurement" .. duration, 1, global.headline1)
    local lgDump = io.open(path .. "_loadgen.output", "w")
    local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
    cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
    cmd:addCommand("./" .. test:getLoadGen() .. " " .. test:getLgArgs())
    cmd:print()
    lgDump:write(cmd:execute(settings.config.verbose))
    if (not settings.config.simulate) then
      ofDev:dumpAll(path .. ".after")
    end
    io.close(lgDump)
    log("done")
  end
  log("Step complete")
  printBar()
end

function Benchmark:collect()
  if (settings.config.testfeature or self:checkExit()) then return end
  for id,test in pairs(self.testcases) do
    printlog("Collecting results ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName(true), global.headline1)
    local cmd = SCPCommand.create()
    cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .."/test_" .. id .. "_*.csv", settings.config.localPath .. "/" .. global.results)
    cmd:execute(settings.config.verbose)
    log("done")
  end
  log("Step complete")
  printBar()
end

function Benchmark:summary(featureOnly)
  if (not settings.config.skipfeature and not settings.config.simulate) then
    if (self.feature_count == 0) then
      print("No features tested")
    else
      local compliance = true;
      for i,feature in pairs(self.featureList) do
        show(string.format("Feature:   ".. ColorCode.white .. "%-24s" .. ColorCode.normal .. "%-24s %s", feature:getName(true), feature:getState()..",".. feature:getRequiredOFVersion(), feature:getStatus()))
        compliance = compliance and (feature:getState() == global.featureState.optional or (feature:isSupported() and feature:getState() == global.featureState.required)) 
      end
      if (not settings.config.testfeature) then
        if (compliance) then printlog("\nTestdevice has passed all required tests for " .. settings.config[global.ofVersion], "lgreen")
        else printlog("\nTestdevice is not compliant with " .. settings.config[global.ofVersion], "lred") end
      end
      printBar()
    end
  end
  if (featureOnly) then return end
  if (settings.config.archive == true) then
    acrhiveResults()
    printBar()
  end
end

function Benchmark:listTestCases()
  if (#self.testcases > 0 ) then printBar() show("Benchmark config:") end
  for id,test in pairs(self.testcases) do
    test:print()
  end
end
