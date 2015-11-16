TestCase = {}
TestCase.__index = TestCase


function TestCase.create(cfgLine)
  local self = setmetatable({}, TestCase)
  self.disabled = false
  self:readConfig(cfgLine)
  return self
end

function TestCase:readConfig(cfgLine)
  self.parameters = {}
  for n,arg in pairs(string.split(cfgLine, ",")) do
    local k,v = string.getKeyValue(arg)
    if (k and v) then
      self.parameters[normalizeKey(k)] = v
    end
  end
  self.name = self.parameters.name
  if (not self.name) then
    logger.printlog("Skipping test, no name specified", "WARN")
    self.disabled = true
    return
  end
  logger.debug("test '" .. self.name .. " added")
  local cfgFile = global.benchmarkFolder .. "/config/" .. self.name .. ".lua"
  print(cfgFile)
  if (not localfileExists(cfgFile)) then
    logger.printlog("Skipping test, config file not found '" .. cfgFile .. "'", "WARN")
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

function TestCase:checkFeatures(benchmark)
  local require = ""
  for i,requires in pairs(self.require) do
    if (not benchmark:isFeatureSupported(requires)) then
      require = require .. "'" .. requires .. "', "
      if (not simulate) then self.disabled = true end
    end
  end
  if (string.len(require) > 0) then
    logger.printlog("Skipping test, unsupported feature(s): " .. string.sub(require, 1 , #require-2), "WARN")
  end
end

function TestCase:setId(id)
  self.settings.id = id 
end

function TestCase:getId()
  return self.settings.id
end

function TestCase:isDisabled()
  if (self == nil) then return true end
  return self.disabled
end

function TestCase:getName(withoutId)
  if (self.settings.id and not withoutId) then return "test_" .. self.settings.id .. "_" .. self.name end
  return self.name
end

function TestCase:getDuration()
  return self.settings.duration
end

function TestCase:getLoadGen()
  return self.config.loadGen
end

function TestCase:getLoadGenFiles()
  return self.files
end

function TestCase:getParameterList()
  return self.parameters
end

function TestCase:createReport(error)
  local config = require("benchmark_config")
  local metric = config.metric[self.config.metric]
  if (not metric) then
    printlog_err("Missing metric configuration in benchmark_config.lua")
    return
  end
  local data = metric.getData(self)
  local plots = metric.getPlots(self)

  local doc = TexDocument.create()
  local title = TexText.create()
  if (not error) then
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{Test " .. self:getId() .. ": " .. self:getName(true) .. "}", "\\end{LARGE}", "\\end{center}")
  else
    title:add("\\begin{center}", "\\begin{LARGE}", "\\textbf{FAILED - Test " .. self:getId() .. ": " .. self:getName(true) .. "}", "\\end{LARGE}", "\\end{center}")  
  end
  local parameter = TexTable.create("|l|r|", "ht")
  for k,v in pairs(self.parameters) do
    if (k ~= "name") then parameter:add(k, v) end
  end
  doc:addElement(title)
  doc:addElement(parameter)
  for _,item in pairs(data) do
    doc:addElement(item)
  end
  for _,item in pairs(plots) do
    doc:addElement(item)
  end  
  doc:generatePDF(self:getName())
end

function TestCase:createErrorReport()
  self:createReport(true)
end

function TestCase:getLgArgs()
  return CommonTest.mapArgs(self, self.config.lgArgs, "lg", false)
end

function TestCase:print(dump)
  CommonTest.print(self.name, self.settings, dump)
end

function TestCase:export(dump)
  CommonTest.export(self.parameters, dump)
end