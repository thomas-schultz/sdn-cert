TestCase = {}
TestCase.__index = TestCase

--------------------------------------------------------------------------------
--  Class for individual test-cases
--------------------------------------------------------------------------------

--- Creates a new test-case from a given configuration line
-- within a benchmark file
function TestCase.create(cfgLine)
  local self = setmetatable({}, TestCase)
  self.disabled = false
  self:readConfig(cfgLine)
  return self
end

--- Reads in the configuration. Creates the parameter list and
-- imports all data from the test-case file.
function TestCase:readConfig(cfgLine)
  self.parameters = {}
  for n,arg in pairs(string.split(cfgLine, ",")) do
    local k,v = string.getKeyValue(arg)
    if (k and v) then
      self.parameters[normalizeKey(k)] = v
    end
  end
  table.sort(self.parameters)
  self.name = self.parameters.name
  if (not self.name) then
    logger.warn("Skipping test, no name specified")
    self.disabled = true
    return
  end
  logger.debug("test '" .. self.name .. " added")
  local cfgFile = global.benchmarkFolder .. "/config/" .. self.name .. ".lua"
  if (not localfileExists(cfgFile)) then
    logger.warn("Skipping test, config file not found '" .. cfgFile .. "'")
    self.disabled = true 
    return
  end
  local config = require(self.name)
  self.config = config
  self.require = CommonTest.readInArgs(config.require) 
  self.settings = table.deepcopy(self.parameters)
  if (config.settings) then
    for k,v in pairs(config.settings) do self.settings[normalizeKey(k)] = v end end
  
  self.files = CommonTest.readInFiles(self, global.benchmarkFolder, self.files)
  self.ofArgs = CommonTest.mapArgs(self, self.config.ofArgs, "of", true)
end

--- Checks if all required features are supported. Print a list+
-- of unsupported features 
function TestCase:checkFeatures(benchmark)
  if (settings:evalOnly()) then return end
  local require = ""
  for i,requires in pairs(self.require) do
    if (not benchmark:isFeatureSupported(requires)) then
      require = require .. "'" .. requires .. "', "
      if (not simulate) then self.disabled = true end
    end
  end
  if (string.len(require) > 0) then
    logger.warn("Skipping test, unsupported feature(s): " .. string.sub(require, 1 , #require-2))
  end
end

--- Sets the Id of a test-case. The Id is used to identify a
-- test-case. Only valid test-cases should get an Id.
function TestCase:setId(id)
  self.settings.id = id 
end

--- Retrieves the Id. 
function TestCase:getId()
  return self.settings.id
end

--- Checks if the test-case is disabled.
function TestCase:isDisabled()
  if (self == nil) then return true end
  return self.disabled
end

--- Returns the name of the test-case. If withoutId is not specified,
-- the complete tag including the Id is returned.
function TestCase:getName(withoutId)
  if (self.settings.id and not withoutId) then return "test_" .. self:getId() .. "_" .. self.name end
  return self.name
end

--- Returns the output path of files belonging to this test-case.
function TestCase:getOutputPath()
  return settings:getLocalPath() .. "/" .. global.results .. "/" .. self.name .. "/"
end

--- Returns the test duration.
function TestCase:getDuration()
  return self.settings.duration
end

--- Returns the specified load-generator.
function TestCase:getLoadGen()
  return self.config.loadGen
end

--- Returns the list of needed files for the load-generator.
function TestCase:getLoadGenFiles()
  return self.files
end

--- Returns the list of parameters.
function TestCase:getParameterList()
  return self.parameters
end

--- Returns the metric name for this test-case
function TestCase:getMetric()
  return self.config.metric
end

--- Returns a configuration string, containing all parameters and
-- their values. Is used to identify corresponding tests with similar
-- configuration.
function TestCase:getParameterConf()
  local conf = ""
  for parameter,value in pairs(self.parameters) do
    conf = conf .. parameter .. "=" .. value .. "," 
  end
  return conf
end

--- Creates the report of this test-case.
function TestCase:createReport(error)
  Reports.createTestReport(self)
end

--- Creates an error report for this test-case.
function TestCase:createErrorReport()
  Reports.createTestReport(self, true)
end

--- Returns a LaTex table of the parameter list.
function TestCase:getParameterTable(metric, blacklist)
  local parameter = TexTable.create("|l|r|l|", "ht")
  parameter:add("\\textbf{parameter}", "\\textbf{value}", "\\textbf{unit}")
  for k,v in pairs(self.parameters) do
    if (k ~= "name" and k ~= blacklist) then parameter:add(k, v, metric.units[k] or "") end
  end
  return parameter
end

--- Returns the list of arguments, which are passed to the OpenFlow
-- rule creation function.
function TestCase:getLgArgs()
  return CommonTest.mapArgs(self, self.config.lgArgs, "lg", false)
end

--- Dumps the current configuration.
function TestCase:print(dump)
  CommonTest.print(self.settings, dump)
end

--- Exports the current configuration.
function TestCase:export(dump)
  CommonTest.export(self.parameters, dump)
end

return TestCase