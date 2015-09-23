TestCase = {}
TestCase.__index = TestCase


function TestCase.create(cfg)
  local self = setmetatable({}, TestCase)
  self.require = {}
  self.prepare = {}
  self.config = {}
  self.config.id = -1 
  self.of_args = {}
  self.files = {}
  self.lg_args = {}
  self.disabled = false
  self:readConfig(cfg)
  return self
end

function TestCase:readConfig(cfg)
  for n,arg in pairs(string.split(cfg, ",")) do
    local k,v = string.getKeyValue(arg)
    if (k and v) then
      self.config[k] = v
      log_debug("test added " .. k .. "=" .. v)
    end
  end
  if not self:getName() then
    printlog_warn("Skipping test, no name specified")
    self.disabled = true
    return
  end
  self.cfgFile = global.benchmarkFolder .. "/" .. self:getName() .. global.cfgFiletype
  if (not localfileExists(self.cfgFile)) then
    printlog_warn("Skipping test, config file not found '" .. self.cfgFile .. "'")
    self.disabled = true 
    return
  end
  local fh = io.open(self.cfgFile)
  while true do
    local line = fh:read()
    if (line == nil) then break end
    local comment = string.find(line, global.ch_comment)
    if not comment then
      local split = string.find(line, global.ch_equal)
      if (split) then
        local k = string.trim(string.sub(line, 1, split-1))
        k = string.lower(string.replaceAll(k, "_", ""))
        local v = string.trim(string.sub(line, split+1, -1))
        self.config[k] = v
      end
    end
  end
  io.close(fh)
  CommonTest.readInOfArgs(self)
  CommonTest.readInLgArgs(self)
  CommonTest.readInFiles(self, global.benchmarkFolder, "Skipping test")
  CommonTest.setSwitch(self)
  CommonTest.setLinks(self)
end

function TestCase:checkFeatures(benchmark)
  local require = ""
  for i,requires in pairs(self.require) do
    if (not benchmark:isFeatureSupported(requires)) then
      require = require .. "'" .. requires .. "', "
      if not simulate then self.disabled = true end
    end
  end
  if (string.len(require) > 0) then
    printlog_warn("Skipping test, unsupported feature(s) " .. string.sub(require, 1 , #require-2))
  end
end

function TestCase:setId(id)
  self.config.id = id 
end

function TestCase:getId()
  return self.config.id
end

function TestCase:get(key)
  return self.config[CommonTest.normalizeKey(key)]
end

function TestCase:doSkip()
  if (self == nil) then return true end
  return self.disabled
end

function TestCase:getName()
  return self.config[global.name]
end

function TestCase:getDuration()
  return self.config[global.duration]
end

function TestCase:getLoopCount()
  return self.config[global.loopCount]
end

function TestCase:getPrepareScript()
  return self.prepare[1]
end

function TestCase:getPrepareCommand()
  self:print()
  return CommonTest.getArgs(self.prepare, self.config)
end

function TestCase:getOfArgs()
  return CommonTest.getArgs(self.of_args, self.config, true)
end

function TestCase:getLoadGen()
  return self:get(global.loadgen)
end

function TestCase:getLoadGenFiles()
  return self.files
end

function TestCase:getLgArgs()
  return CommonTest.getArgs(self.lg_args, self.config)
end

function TestCase:print(dump)
  CommonTest.print(self:getName(), self.config, dump)
end