Settings = {}
Settings.__index = Settings
        
--------------------------------------------------------------------------------
--  settings class for global preferences
--------------------------------------------------------------------------------
        
--- Creates a new instance from given file.
function Settings.create(configFile)
  local self = setmetatable({}, Settings)
  self.config = {}
  self:readSettings(configFile)
  return self
end

--- Reads in the settings file. Sets the default values if not
-- specified in the settings file
function Settings:readSettings(configFile)
  local f = io.popen("pwd 2>&1")
  self.config.localpath = f:read("*line")
  local fh = io.open(configFile)
  self.config.verbose       = false
  self.config.simulate      = false
  self.config.archive       = false
  self.config.runtex        = false
  self.config.checksetup    = false
  self.config.skipfeature   = false
  self.config.evalonly      = false
  self.config[global.ofVersion] = "OpenFlow10"
  while (true) do
    local line = fh:read()
    if (line == nil) then break end
    local comment = string.find(line, global.ch_comment)
    if (not comment) then
      local k,v = string.getKeyValue(line)
      if (k and v) then self.config[k] = v end
    end
  end
  io.close(fh)
  if (self.config.debug == true) then debugMode = true end
  if (self:isLocal()) then self.config[string.lower(global.loadgenHost)] = nil end
  if (self.config[global.loadgenWd] == nil) then self.config[global.loadgenWd] = "/tmp" end
  self.ports = {}
  for n,link in pairs(string.split(self:get(global.phyLinks), ",")) do
    local split = string.find(link, global.ch_connect)
    local ofLinks = tonumber(string.sub(link, 1, split-1))
    local lgLinks = tonumber(string.sub(link, split+1, -1))
    if (ofLinks == nil or lgLinks == nil) then
      logger.printlog("Invalid link: '" .. link .. "'")
      exit()
    end
    self.ports[n] = {}
    self.ports[n].of = ofLinks
    self.ports[n].lg = lgLinks
    logger.debug("added link " .. ofLinks .. global.ch_connect .. lgLinks)
  end
  if (#self.ports == 0) then
    logger.err("Invalid settings, no phyLinks are assigned")
    exit()
  end
  if (#self.ports == 1) then
    logger.warn("You have configured only a single link, most of the features require at least two!")
  end
end

--- Returns the value of the given key. Keys are always stored in lower case.
function Settings:get(key)
  return self.config[string.lower(key)]
end

--- Returns the current path, from which the program was started.
function Settings:getLocalPath()
  return self.config.localpath
end

--- Checks if the measurement host is on this local host too.
function Settings:isLocal()
  return self.config["local"] == true
end

--- Checks if the program is run in verbose mode.
function Settings:isVerbose()
  return self.config.verbose == true
end

--- Checks if the program is in simulation mode. In simulation mode
-- no test are performed, but files and folder can be created or deleted.
function Settings:doSimulate()
  return settings.config.simulate == true
end

--- Checks if the feature-testing will be skipped.
function Settings:doSkipfeature()
  return self.config.skipfeature == true
end

--- Checks if the result should be archived at the end.
function Settings:doArchive()
  return self.config.archive == true
end

--- Checks if the program should compile the LaTeX documents.
function Settings:doRunTex()
  return self.config.runtex == true
end

--- Checks uf the program should only perform evaluation and no testing.
-- This function is experimental, and only works if the data from the
-- actual test is still present.
function Settings:evalOnly()
  return self.config.evalonly == true
end

--- Returns the global OpenFlow protocol version.
function Settings:getOFVersion()
  return settings.config[global.ofVersion]
end

--- Checks if the program performs only a single feature-test.
function Settings:isTestFeature()
  return (settings.config.testfeature ~= nil)
end

--- Get the name of the feature-test in single feature mode. 
function Settings:getTestFeature()
  return settings.config.testfeature
end

--- Verifies all settings.
function Settings:verify()
  -- TODO
  local cmd = CommandLine.getRunInstance(self:isLocal()).create()
  cmd:addCommand("mkdir -p " .. self.config[global.loadgenWd])
  cmd:execute(false)
end

--- Prints all settings information.
function Settings:print()
  logger.printBar()
  logger.print("Settings:", 0, global.headline1)
  local t = {}
  for key,value in pairs(self.config) do
    table.insert(t,key)
  end
  table.sort(t)
  for i,name in pairs(t) do
    logger.print(string.format("%-20s = %s", name, tostring(self.config[name])), 2)
  end
  logger.print()
end

return Settings
  