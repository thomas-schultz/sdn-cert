Benchmark = {}
Benchmark.__index = Benchmark


function Benchmark.create(config)
  local self = setmetatable({}, Benchmark)
  self.testcases = {}
  self.features = {}
  self.feature_list = global.feature_list
  self.feature_count = 0
  self.config = config
  self:readConfig(config)
  return self
end

-- read in the benchmark configuration
function Benchmark:readConfig(config)
  if settings.config.testfeature then return end
  local fh = io.open(config)
  while true do
    local line = fh:read()
    if line == nil then break end
    if (not (string.sub(line, 1,1) == global.ch_comment) and #line > 0 ) then
      local test = TestCase.create(line)
      table.insert(self.testcases, test)
      log_debug("added testcase " .. line)
    end
  end
  io.close(fh)
  self:checkExit()
end

function Benchmark:checkExit()
  if #self.testcases == 0 then
    printlog("Exiting: No tests left")
    exit()
  end
end

function Benchmark:getFeatures()
  if settings.config.testfeature then
    self.feature_list = {}
    local feature = Feature.create(settings.config.testfeature)
    if feature:doSkip() then return end
    self.features[settings.config.testfeature] = feature
    if not feature:doSkip() then
      self.feature_count = 1
      table.insert(self.feature_list, 1, feature)        
      return
    else
      show("No such feature!")
      exit(1)
    end
  end
  local fh = io.open(settings.config.localPath .. "/" .. global.feature_tests .. "/" .. self.feature_list)
  self.feature_list = {}
  self.feature_count = 0
  while true do
    local line = fh:read()
    if line == nil then break end
    if (not (string.sub(line, 1,1) == global.ch_comment) and string.len(line) > 0 ) then
      local feature = Feature.create(line)
      if not feature:doSkip() then
        self.features[line] = feature
        self.feature_count = self.feature_count + 1
        table.insert(self.feature_list, self.feature_count, feature)    
        log_debug("added feature " .. line)    
      end
    end
  end
end

function Benchmark:exportFeatures()
  if settings.config.skipfeature then return end
  local file = io.open(global.feature_file, "w")
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
  self.feature_list = {}
  self.feature_count = 0
  if (not file_exists(global.feature_file)) then return end
  local fh = io.open(global.feature_file)
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
        table.insert(self.feature_list, self.feature_count, feature)
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
  printlog("Cleaning up testing system")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgen_wd))
  cmd:addCommand("mkdir -p " .. global.results)
  cmd:addCommand("rm -f " .. global.results .. "/*")
  cmd:addCommand("mkdir -p " .. global.scripts)
  cmd:addCommand("rm -f " .. global.scripts .. "/*")
  cmd:execute()
  local cmd = CommandLine.create()
  cmd:addCommand("mkdir -p " .. settings.config.localPath .. "/" .. global.results)
  cmd:addCommand("rm -f " .. settings.config.localPath .. "/" .. global.results .. "/*")
  cmd:execute(settings.config.verbose)
  ofReset()
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
  for i,feature in pairs(self.feature_list) do
    printlog("Testing feature ( " .. i .. " / " .. self.feature_count .. " ): " .. feature:getName())
    feature:runTest()
    if not settings.config.simulate then showIndent(feature:getStatus()) end
  end
  log("Step complete")
  if (settings.config.testfeature) then
    printBar()
    self:summary()
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
  if settings.config.testfeature then return end
  local testcases = {}
  for id,test in pairs(self.testcases) do
    printlog("Preparing test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName())
    test:checkFeatures(self)
    if (not test:doSkip()) then
      local files = test:getLoadGenFiles()
      for i,file in pairs(files) do
        showIndent("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")")
        local cmd = SCPCommand.create()
        cmd:switchCopyTo(settings:isLocal(), settings.config.localPath .. "/" .. global.benchmark_files .. "/" .. file, settings:get(global.loadgen_wd) .. "/" .. global.scripts)
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
  if settings.config.testfeature then return end
  self:checkExit()
  for id,test in pairs(self.testcases) do
    printlog("Running test ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName())
    test:setId(id)
    if (settings.config.verbose) then test:print() end
    if (test:getPrepareScript()) then
      showIndent("preparing OpenFlow script (may take a while)")
      local cmd = CommandLine.create(settings.config.localPath .. "/" .. global.benchmark_files .. "/" .. test:getPrepareCommand())
      cmd:execute(settings.config.verbose)
    end
    -- reseting open-flow device
    ofReset() 
    -- configure open-flow device
    showIndent("configuring OpenFlow device")
    local cmd = CommandLine.create(settings.config.localPath .. "/" .. global.benchmark_files .. "/" .. test:getOfCommand())
    cmd:sendToBackground()
    showIndent("Waiting for job to be finished")
    if (not settings.config.simulate) then sleep(global.timeout) end
    -- start loadgen
    local duration = test:getDuration()
    if (duration) then
      local loops = test:getLoopCount() or 1
      duration = " (measuring for " .. loops .. "x " .. duration .. " sec)"
    else
      duration = " (unknown duration)"
    end
    showIndent("starting measurement" .. duration)
    local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
    cmd:addCommand("cd " .. settings:get(global.loadgen_wd) .. "/MoonGen")
    cmd:addCommand("./" .. test:getLoadGen() .. " " .. test:getLgArgs())
    cmd:execute(settings.config.verbose)
    log("done")
  end
  log("Step complete")
  printBar()
end

function Benchmark:collect()
  if settings.config.testfeature then return end
  for id,test in pairs(self.testcases) do
    printlog("Collecting results ( " .. id .. " / " .. #self.testcases .. " ): " .. test:getName())
    local cmd = SCPCommand.create()
    cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgen_wd) .. "/" .. global.results .."/test_" .. id .. "_*.csv", settings.config.localPath .. "/" .. global.results)
    cmd:execute(settings.config.verbose)
    log("done")
  end
  log("Step complete")
  printBar()
end

function Benchmark:summary()
  if (not settings.config.skipfeature and not settings.config.simulate) then
    if (self.feature_count == 0) then print("No features tested") end
    for i,feature in pairs(self.feature_list) do
      show(string.format("Feature   %-22s %10s", feature:getName(), feature:getStatus()))
    end
    printBar()
  end
end

function Benchmark:listTestCases()
  if (#self.testcases > 0 ) then printBar() show("Benchmark config:") end
  for id,test in pairs(self.testcases) do
    test:print()
  end
end
