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
  self.skip = false
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
    self.skip = true
    return
  end
  self.cfg_file = global.benchmark_configs .. "/" .. self:getName() .. global.cfg_filetype
  if not file_exists(self.cfg_file) then
    printlog_warn("Skipping test, config file not found '" .. self:getName() .. global.filetype .. "'")
    self.skip = true 
  end
  local fh = io.open(self.cfg_file)
  while true do
    local line = fh:read()
    if line == nil then break end
    local comment = string.find(line, global.ch_comment)
    if not comment then
      local split = string.find(line, global.ch_equal)
      if split then
        local k = string.trim(string.sub(line, 1, split-1))
        k = string.lower(string.replaceAll(k, "_", ""))
        local v = string.trim(string.sub(line, split+1, -1))
        self.config[k] = v
      end
    end
  end
  io.close(fh)
  CommonTest.readInPrepArgs(self)
  CommonTest.readInOfArgs(self)
  if not file_exists(global.benchmark_files .. "/" .. self:getOfScript()) then
    printlog_warn("Skipping test, open-flow script not found '" .. self:getOfScript() .. "'")
    self.skip = true 
  end
  CommonTest.readInLgArgs(self)
  for n,file in pairs(string.split(self:get(global.copy_files), ",")) do
    file = string.trim(file)
    if not file_exists(global.benchmark_files .. "/" .. file) then
      printlog_warn("Skipping test, missing file '" .. file .. "'")
      self.skip = true
    else
      table.insert(self.files, n, file)
      self.config["file" .. tonumber(n)] = settings:get(global.loadgen_wd) .. "/" .. global.scripts .. "/" .. file
    end
  end
  self.config.ip = settings:get(global.sdn_ip)
  self.config.port = settings:get(global.sdn_port)
  CommonTest.setConnections(self)
end

function TestCase:checkFeatures(benchmark)
  local require = ""
  for i,requires in pairs(self.require) do
    if (not benchmark:isFeatureSupported(requires)) then
      require = require .. "'" .. requires .. "', "
      if not simulate then self.skip = true end
    end
  end
  if (#require > 0) then
    printlog_warn("Skipping test, unsupported feature(s) " .. string.sub(require, 1 , #require-2))
  end
end

function TestCase:setId(id)
  self.config.id = id 
end

function TestCase:get(key)
  return self.config[CommonTest.normalizeKey(key)]
end

function TestCase:doSkip()
  if (self == nil) then return true end
  return self.skip
end

function TestCase:getName()
  return self.config[global.name]
end

function TestCase:getDuration()
  return self.config[global.duration]
end

function TestCase:getLoopCount()
  return self.config[global.loop_count]
end

function TestCase:getPrepareScript()
  return self.prepare[1]
end

function TestCase:getPrepareCommand()
  self:print()
  return CommonTest.getArgs(self.prepare, self.config)
end

function TestCase:getOfScript()
  return self.of_args[1]
end

function TestCase:getOfCommand()
  return CommonTest.getArgs(self.of_args, self.config)
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

function TestCase:print()
  CommonTest.print(self:getName(), self.config)
end