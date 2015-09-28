Feature = {}
Feature.__index = Feature
 
 
function Feature.create(name)
  local self = setmetatable({}, Feature)
  setmetatable(Feature,{__index = Feature})
  self.name = name
  self.supported = false
  self.disabled = false
  self:readConfig()
  return self
end

function Feature:readConfig()
  local configFile = "config/" .. self.name .. ".lua"
  if (not localfileExists(global.featureFolder .. "/" .. configFile)) then
    printlog_warn("Disabled feature '" .. self:getName() .. "', missing file '" .. configFile .. "'")
    self.disabled = true
    return
  end
  local config = require(self.name)
  self.config = config
  self.settings = config.settings

  if (Settings:isTestFeature() and Settings:getTestFeature() ~= self:getName()) then return end
  local ver_comp = compareVersion(self:getRequiredOFVersion(), Settings:getOFVersion())
  if (ver_comp == nil or ver_comp < 0) then
    printlog_warn("Disabled feature '" .. self:getName() .. "', version is '" .. Settings:getOFVersion() .. "' but '" .. self:getRequiredOFVersion() .. "' is required")
    self.disabled = true
  end
  self.settings.name = self:getName()
  self.settings.require = self:getRequiredOFVersion()
  self.settings.state = self.config.state or global.featureState.undefined
  
  self.files = {configFile, "feature_config.lua"}
  self.files = CommonTest.readInFiles(self, global.featureFolder, self.files, true)
  self.lgArgs = CommonTest.mapArgs(self, self.config.lgArgs, "lg", false, true)
  self.ofArgs = CommonTest.mapArgs(self, self.config.ofArgs, "of", true, true)
end

function Feature:runTest()
  if (settings.config.verbose) then self:print() end
  -- copying files
  local files = self.files
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
  local flowData = ofDev:getFlowData(self)
  ofDev:createAllFiles(flowData, path)
  ofDev:installAllFiles(path, "_ovs.output")
  ofDev:dumpAll(path .. ".before")
  if (not settings.config.simulate) then sleep(global.timeout) end
  
  -- start loadgen
  showIndent("Starting feature test (~10 sec)", 1, global.headline2)
  local lgDump = io.open(path .. "_loadgen.output", "w")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
  cmd:addCommand("./" .. self:getLoadGen() .. " " .. self.lgArgs)
  lgDump:write(cmd:execute(settings.config.verbose))
  if (not settings.config.simulate) then
    ofDev:dumpAll(path .. ".after")
  end
  io.close(lgDump)
  
  -- check result
  showIndent("Fetching data and checking result", 1, global.headline2)
  local cmd = SCPCommand.create()
  cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .. "/feature_" .. self:getName() .. "*", settings.config.local_path .. "/" .. global.results)
  local out = cmd:execute(settings.config.verbose)
  if (not out) then
    self.reason = "Feature test failed, no files were created"
    ofDev:reset()
    return
  end 
  local cmd = CommandLine.create("cat " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result")
  out = cmd:execute()
  if (settings.config.simulate and not out) then
    out = "simulation mode" end
  if (string.find(out, "cat: " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result:")) then
    out = "Feature test failed to run" end
  if (not settings.config.simulate) then
    if (string.trim(out) == "passed") then self.supported = true
    else self.reason = string.trim(string.replaceAll(out, "\n", " ")) end
    log(self:getStatus())  
  end
  ofDev:reset()
end

function Feature:isDisabled()
  return self.disabled
end

function Feature:getName()
  return self.name
end

function Feature:getRequiredOFVersion()
  return self.config.require
end

function Feature:getState()
  return self.settings.state
end

function Feature:isSupported()
  return self.supported
end

function Feature:getStatus()
  if self:isSupported() then
    return ColorCode.lgreen .. "Test passed" .. ColorCode.normal
  else
    return ColorCode.lred .. "Test failed" .. ColorCode.normal .. " (" .. self.reason .. ")"
 end
end

function Feature:getLoadGen()
  return self.config.loadGen
end

function Feature:getLoadGenFiles()
  return self.files
end

function Feature:print(dump)
  CommonTest.print(self:getName(), self.settings, dump)
end