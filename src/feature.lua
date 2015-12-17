Feature = {}
Feature.__index = Feature

package.path = package.path .. ';' .. global.featureFolder .. '/?.lua'
package.path = package.path .. ';' .. global.featureFolder .. '/config/?.lua'

 
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
    logger.warn("Disabled feature '" .. self:getName() .. "', missing file '" .. configFile .. "'")
    self.disabled = true
    return
  end
  local config = require(self.name)
  self.config = config
  self.settings = config.settings

  if (Settings:isTestFeature() and Settings:getTestFeature() ~= self:getName()) then return end
  local ver_comp = compareVersion(self:getRequiredOFVersion(), Settings:getOFVersion())
  if (ver_comp == nil or ver_comp < 0) then
    logger.warn("Disabled feature '" .. self:getName() .. "', version is '" .. Settings:getOFVersion() .. "' but '" .. self:getRequiredOFVersion() .. "' is required")
    self.disabled = true
  end
  self.settings.name = self:getName()
  self.settings.require = self:getRequiredOFVersion()
  self.settings.state = self.config.state or global.featureState.undefined
  
  self.files = {configFile, global.featureLibrary .. ".lua"}
  self.files = CommonTest.readInFiles(self, global.featureFolder, self.files, true)
  self.lgArgs = CommonTest.mapArgs(self, self.config.lgArgs, "lg", false, true)
  self.ofArgs = CommonTest.mapArgs(self, self.config.ofArgs, "of", true, true)
end

function Feature:runTest()
  if (settings.config.verbose) then self:print() end
  -- copying files
  local files = self.files
  for i,file in pairs(files) do
    logger.print("Copying file " .. i .. "/" .. #files .. " (" .. file .. ")", 1, global.headline2)
    local cmd = SCPCommand.create()
    cmd:switchCopyTo(settings:isLocal(), settings:getLocalPath() .. "/" .. global.featureFolder .. "/" .. file, settings:get(global.loadgenWd) .. "/" .. global.scripts)
    cmd:execute(settings.config.verbose)
  end
  -- configure open-flow device
  local dur = global.ofSetupTime + global.ofResetTimeOut
  logger.print("Configuring OpenFlow device (~" .. dur .. " sec)", 1, global.headline2)
  local path = settings:getLocalPath() .. "/" .. global.results .. "/features"
  Setup.createFolder(path)
  local template = path .. "/feature_" .. self:getName()
  local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort], self.config[global.requires])
  ofDev:reset()
  -- wait for reset process to finish
  sleep(global.ofResetTimeOut)
  local flowData = ofDev:getFlowData(self)
  ofDev:createAllFiles(flowData, template)
  ofDev:installAllFiles(template, "_ovs-output")
  ofDev:dumpAll(template .. "_flowdump-before")
  if (not settings.config.simulate) then sleep(global.ofSetupTime) end
  
  -- start loadgen
  logger.print("Starting feature test (~10 sec)", 1, global.headline2)
  local lgDump = io.open(template .. "_loadgen-output", "w")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
  cmd:addCommand("./" .. self:getLoadGen() .. " " .. self.lgArgs)
  lgDump:write(cmd:execute(settings.config.verbose))
  if (not settings.config.simulate) then
    ofDev:dumpAll(template .. "_flowdump_after")
  end
  io.close(lgDump)
  
  -- check result
  logger.print("Fetching data and checking result", 1, global.headline2)
  local cmd = SCPCommand.create()
  cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .. "/feature_" .. self:getName() .. "*", path)
  local out = cmd:execute(settings.config.verbose)
  if (not out) then
    self.reason = "Feature test failed, no files were created"
    ofDev:reset()
    return
  end 
  local cmd = CommandLine.create("cat " .. template .. "_result")
  out = cmd:execute()
  if (settings.config.simulate and not out) then
    out = "simulation mode" end
  if (string.find(out, "cat: " .. template .. "_result:")) then
    out = "Feature test failed to run" end
  if (not settings.config.simulate) then
    if (string.trim(out) == "passed") then self.supported = true
    else self.reason = string.trim(string.replaceAll(out, "\n", " ")) end
    logger.log(self:getStatus())  
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
  return self.config.state
end

function Feature:isSupported()
  return self.supported
end

function Feature:getStatus(noColor)
  local color
  if (noColor) then color = Logger.noColorCode
  else color = Logger.ColorCode end
  
  if (self:isSupported()) then
    return color.lgreen .. "Test passed" .. color.normal
  else
    return color.lred .. "Test failed" .. color.normal
    --return color.lred .. "Test failed" .. color.normal .. " (" .. self.reason .. ")"
  end
end

function Feature:getTexStatus()
  if (self:isSupported()) then
    return "{\\color{darkgreen} supported}"
  else
    return "{\\color{darkred} not supported}"
  end
end

function Feature:getLoadGen()
  return self.config.loadGen
end

function Feature:getLoadGenFiles()
  return self.files
end

function Feature:print(dump)
  CommonTest.print(self.settings, dump)
end