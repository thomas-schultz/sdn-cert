Feature = {}
Feature.__index = Feature

    
function Feature.create(name)
  local self = setmetatable({}, Feature)
  self.config = {}
  self.config.name = name
  self.of_args = {}
  self.lg_args = {}
  self.files = {}
  self.disabled = false
  self.supported = false
  self:readConfig(global.feature_tests .. "/" .. name .. ".cfg")
  return self
end

function Feature:readConfig(config_file)
  if not file_exists(config_file) then
    printlog_warn("Disabled feature '" .. self:get("name") .. "', missing file '" .. config_file .. "'")
    self.disabled = true
    return
  end
  local fh = io.open(config_file)
  while true do
    local line = fh:read()
    if line == nil then break end
    local comment = string.find(line, global.ch_comment)
    if not comment then
      local k,v = string.getKeyValue(line)
      if (k and v) then
        self.config[k] = v
        log_debug("feature ".. self.config.name .. " added " .. k .. "=" .. v)
      end
    end
  end
  io.close(fh)
  if (settings.config.testfeature and settings.config.testfeature ~= self:getName()) then return end 
  local ver_comp = compareVersion(self.config[global.requires], settings.config[global.ofVersion])
  if (ver_comp == nil or ver_comp < 0) then
    printlog_warn("Disabled feature '" .. self:getName() .. "', version is '" .. settings:get(global.ofVersion) .. "' but '" .. self.config[global.requires] .. "' is required")
    self.disabled = true
  end
  CommonTest.readInOfArgs(self)
  if (not file_exists(global.feature_tests.. "/" .. self:getOfScript())) then
    printlog_warn("Disabled feature, OpenFlow script not found '" .. self:getOfScript() .. "'")
    self.disabled = true
  end
  CommonTest.readInLgArgs(self)
  for n,file in pairs(string.split(self:get(global.copy_files), ",")) do
    file = string.trim(file)
    if not file_exists(global.feature_tests .. "/" .. file) then
      log_warn("Disabled feature " .. self:getName() .. ", missing file '" .. file .. "'")
      self.disabled = true
    else
      table.insert(self.files, n, file)
      self.config["file" .. tonumber(n)] = settings:get(global.loadgen_wd) .. "/" .. global.scripts .. "/" .. file
    end
  end
  self.config.ip = settings:get(global.sdn_ip)
  self.config.port = settings:get(global.sdn_port)
  CommonTest.setConnections(self)
end

function Feature:get(key)
  return self.config[CommonTest.normalizeKey(key)]
end

function Feature:runTest()
  -- copying
  local files = self:getLoadGenFiles()
  for i,file in pairs(files) do
    showIndent("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")")
    local cmd = SCPCommand.create()
    cmd:switchCopyTo(settings:isLocal(), settings.config.local_path .. "/" .. global.feature_tests .. "/" .. file, settings:get(global.loadgen_wd) .. "/" .. global.scripts)
    cmd:execute(settings.config.verbose)
  end
  -- reseting open-flow device
  ofReset()
  -- configure open-flow device
  local cmd = CommandLine.create(settings.config.local_path .. "/" .. global.feature_tests .. "/" .. self:getOfCommand())
  cmd:execute(settings.config.verbose)
  showIndent("Waiting for job to be finished")
  if (not settings.config.simulate) then sleep(global.timeout) end
  -- start loadgen
  showIndent("Starting feature test (~10 sec)")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgen_wd) .. "/MoonGen")
  cmd:addCommand("./" .. self:getLoadGen() .. " " .. self:getLgArgs())
  cmd:execute(settings.config.verbose)
  -- check result
  showIndent("Fetching result")
  local cmd = SCPCommand.create()
  cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgen_wd) .. "/" .. global.results .. "/feature_" .. self:getName() .. "*", settings.config.local_path .. "/" .. global.results)
  cmd:execute(settings.config.verbose)
  showIndent("Checking result")
  local cmd = CommandLine.create("cat " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result")
  local out = cmd:execute()
  if (not settings.config.simulate) then
    if (string.trim(out) == "passed") then self.supported = true
    else self.reason = out end
    log(self:getStatus())  
  end
  ofReset()
end

function Feature:doSkip()
  return self.disabled
end

function Feature:getName()
  return self.config.name
end

function Feature:getStatus()
  if self:isSupported() then
    return "Test passed"
  else
    return "Test failed (" .. self.reason .. ")"
 end
end

function Feature:isSupported()
  return self.supported
end

function Feature:getOfScript()
  return self.of_args[1]
end

function Feature:getOfCommand()
  return CommonTest.getArgs(self.of_args, self.config)
end

function Feature:getLoadGen()
  return self:get(global.loadgen)
end

function Feature:getLoadGenFiles()
  return self.files
end

function Feature:getLgArgs()
  return CommonTest.getArgs(self.lg_args, self.config)
end

function Feature:print()
  CommonTest.print(self:getName(), self.config)
end