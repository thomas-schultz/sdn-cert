TestCase = {}
TestCase.__index = TestCase


function TestCase.create(cfgLine)
  local self = setmetatable({}, TestCase)
  self.disabled = false
  self:readConfig(cfgLine)
  return self
end

function TestCase:readConfig(cfgLine)
  self.settings = {}
  for n,arg in pairs(string.split(cfgLine, ",")) do
    local k,v = string.getKeyValue(arg)
    if (k and v) then
      self.settings[k] = v
    end
  end
  self.name = self.settings.name
  if (not self.name) then
    printlog_warn("Skipping test, no name specified")
    self.disabled = true
    return
  end
  log_debug("test '" .. self.name .. " added")
  local cfgFile = global.benchmarkFolder .. "/config/" .. self.name .. ".lua"
  if (not localfileExists(cfgFile)) then
    printlog_warn("Skipping test, config file not found '" .. cfgFile .. "'")
    self.disabled = true 
    return
  end
  local config = require(self.name)
  self.config = config
  self.require = CommonTest.readInArgs(config.require)
  if (self.config.settings) then 
    for k,v in pairs(self.config.settings) do self.settings[k] = v end end
  self.settings.name = self.name
  for k,v in pairs(config.settings) do self.settings[k] = v end
  
  self.files = CommonTest.readInFiles(self, global.benchmarkFolder, self.files)
  self.ofArgs = CommonTest.mapArgs(self, self.config.ofArgs, "of", true)
  self:print()
end

function TestCase:checkFeatures(benchmark)
  local require = ""
  for i,requires in pairs(self.require) do
    if (not benchmark:isFeatureSupported(requires)) then
      require = require .. "'" .. requires .. "', "
      if (not simulate) then self.disabled = true end
    end
  end
  if (#require > 0) then
    printlog_warn("Skipping test, unsupported feature(s): " .. string.sub(require, 1 , #require-2))
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

function TestCase:getLgArgs()
  return CommonTest.mapArgs(self, self.config.lgArgs, "lg", false)
end

function TestCase:print(dump)
  CommonTest.print(self.name, self.settings, dump)
end