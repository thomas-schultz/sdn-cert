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
  self:readConfig(global.featureFolder .. "/config/" .. name .. ".cfg")
  return self
end

function Feature:readConfig(configFile)
  if (not localfileExists(configFile)) then
    printlog_warn("Disabled feature '" .. self:get("name") .. "', missing file '" .. configFile .. "'")
    self.disabled = true
    return
  end
  local fh = io.open(configFile)
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
  self.state = self.config[global.state] or global.featureState.undefined
  CommonTest.readInOfArgs(self)
  CommonTest.readInLgArgs(self)
  CommonTest.readInFiles(self, global.featureFolder, "Disabled feature")
  CommonTest.setSwitch(self)
  CommonTest.setLinks(self)
end

function Feature:get(key)
  return self.config[CommonTest.normalizeKey(key)]
end

function Feature:runTest()
  if (settings.config.verbose) then self:print() end
  -- copying
  local files = self:getLoadGenFiles()
  for i,file in pairs(files) do
    showIndent("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")", 1, global.headline2)
    local cmd = SCPCommand.create()
    cmd:switchCopyTo(settings:isLocal(), settings.config.local_path .. "/" .. global.featureFolder .. "/" .. file, settings:get(global.loadgenWd) .. "/" .. global.scripts)
    cmd:execute(settings.config.verbose)
  end
  -- configure open-flow device
  showIndent("Configuring OpenFlow device (~" .. global.timeout .. " sec)", 1, global.headline2)
  local path = settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName()
  local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort], self.config[global.requires])
  ofDev:reset()
  local flowData = ofDev:getFeatureFlows(self:getName(), unpack(self:getOfArgs()))
  ofDev:createAllFiles(flowData, path)
  if (not settings.config.simulate) then
    ofDev:installAllFiles(path, "_ovs.output")
    ofDev:dumpAll(path .. ".before")
    sleep(global.timeout)
  end
  
  -- start loadgen
  showIndent("Starting feature test (~10 sec)", 1, global.headline2)
  local lgDump = io.open(path .. "_loadgen.output", "w")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
  cmd:addCommand("./" .. self:getLoadGen() .. " " .. self:getLgArgs())
  lgDump:write(cmd:execute(settings.config.verbose))
  if (not settings.config.simulate) then
    ofDev:dumpAll(path .. ".after")
  end
  io.close(lgDump)
  
  -- check result
  showIndent("Fetching data and checking result", 1, global.headline2)
  local cmd = SCPCommand.create()
  cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .. "/feature_" .. self:getName() .. "*", settings.config.local_path .. "/" .. global.results)
  cmd:execute(settings.config.verbose)
  local cmd = CommandLine.create("cat " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result")
  local out = cmd:execute()
  if (settings.config.simulate and not out) then
    out = "simulation mode" end
  if (string.find(out, "cat: " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result:")) then
    out = "Feature test failed somehow, no result file was created" end
  if (not settings.config.simulate) then
    if (string.trim(out) == "passed") then self.supported = true
    else self.reason = string.trim(string.replaceAll(out, "\n", " ")) end
    log(self:getStatus())  
  end
  ofDev:reset()
end

function Feature:doSkip()
  return self.disabled
end

function Feature:getName()
  return self.config.name
end

function Feature:getStatus()
  if self:isSupported() then
    return ColorCode.lgree .. "Test passed" .. ColorCode.normal
  else
    return ColorCode.lred .. "Test failed" .. ColorCode.normal .. " (" .. self.reason .. ")"
 end
end

function Feature:getOfVersion()
  return self.config[global.requires]
end

function Feature:getState()
  return self.state
end

function Feature:isSupported()
  return self.supported
end

function Feature:getOfArgs()
  return CommonTest.getArgs(self.of_args, self.config, true)
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

function Feature:print(dump)
  CommonTest.print(self:getName(), self.config, dump)
end