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
  CommonTest.readInOfArgs(self)
  CommonTest.readInLgArgs(self)
  CommonTest.readInFiles(self, "Disabled feature")
  CommonTest.setSwitch(self)
  CommonTest.setLinks(self)
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
    cmd:switchCopyTo(settings:isLocal(), settings.config.local_path .. "/" .. global.featureFolder .. "/" .. file, settings:get(global.loadgenWd) .. "/" .. global.scripts)
    cmd:execute(settings.config.verbose)
  end
  -- configure open-flow device
  showIndent("Configuring OpenFlow device (~5 sec)")
  local ofDev = OpenFlowDevice.create(settings.config[global.switchIP], settings.config[global.switchPort])
  ofDev:reset()
  local flows = ofDev:getFeatureFlows(self:getName(), unpack(self:getOfArgs()))
  local output = settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName()
  ofDev:createFlowFile(flows, output .. "_flows.ovs")
  local flowDump = io.open(output .. "_flows.dump", "w")
  flowDump:write("Installing flows:\n" .. ofDev:installFlows(output .. "_flows.ovs") .. "\n")
  flowDump:write("before feature test:\n" .. ofDev:dumpFlows(self.config[global.requires]) .. "\n")
  if (not settings.config.simulate) then sleep(global.timeout) end
  
  -- start loadgen
  showIndent("Starting feature test (~10 sec)")
  local lgDump = io.open(output .. "_loadgen.out", "w")
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd) .. "/MoonGen")
  cmd:addCommand("./" .. self:getLoadGen() .. " " .. self:getLgArgs())
  lgDump:write(cmd:execute(settings.config.verbose))
  io.close(lgDump)
  
  flowDump:write("after feature test:\n" .. ofDev:dumpFlows(self.config[global.requires]))
  io.close(flowDump)
  
  -- check result
  showIndent("Fetching result")
  local cmd = SCPCommand.create()
  cmd:switchCopyFrom(settings:isLocal(), settings:get(global.loadgenWd) .. "/" .. global.results .. "/feature_" .. self:getName() .. "*", settings.config.local_path .. "/" .. global.results)
  cmd:execute(settings.config.verbose)
  showIndent("Checking result")
  local cmd = CommandLine.create("cat " .. settings.config.localPath .. "/" .. global.results .. "/feature_" .. self:getName() .. ".result")
  local out = cmd:execute()
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
    return "Test passed"
  else
    return "Test failed (" .. self.reason .. ")"
 end
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

function Feature:print()
  CommonTest.print(self:getName(), self.config)
end