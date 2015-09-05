Settings = {}
Settings.__index = Settings
        
function Settings.create(configFile)
  local self = setmetatable({}, Settings)
  self.config = {}
  self:readSettings(configFile)
  return self
end

-- read in the settings file
function Settings:readSettings(configFile)
  local f = io.popen("pwd 2>&1")
  self.config.local_path = f:read("*line")
  local fh = io.open(configFile)
  self.config.localPath    = "."
  self.config.verbose       = false
  self.config.simulate      = false
  self.config.archive       = false
  self.config.checkSetup    = false
  self.config.skipfeature   = false
  self.config.skipBenchmark = false
  self.config[global.ofVersion] = "OpenFlow10"
  while true do
    local line = fh:read()
    if line == nil then break end
    local comment = string.find(line, global.ch_comment)
    if (not comment) then
      local k,v = string.getKeyValue(line)
      if (k and v) then self.config[k] = v end
    end
  end
  io.close(fh)
  if (self.config.debug == true) then debug_mode = true end
  if (self:isLocal()) then self.config[string.lower(global.loadgenHost)] = nil end
  if (self.config[global.loadgenWd] == nil) then self.config[global.loadgenWd] = "/tmp" end
  self.ports = {}
  for n,link in pairs(string.split(self:get(global.phyLinks), ",")) do
    local split = string.find(link, global.ch_connect)
    local of_port = tonumber(string.sub(link, 1, split-1))
    local lg_port = tonumber(string.sub(link, split+1, -1))
    if (of_port == nil or lg_port == nil) then
      printlog("Invalid link: '" .. link .. "'")
      exit()
    end
    self.ports[n] = {}
    self.ports[n].of = of_port
    self.ports[n].lg = lg_port
    log_debug("added port " .. of_port .. global.ch_connect .. lg_port)
  end
  if (#self.ports == 0) then
    printlog("Invalid settings, no phyLinks are assigned")
    exit()
  end
  if (#self.ports == 1) then
    printlog_warn("You have configured only a single link, most of the features require at least two!")
  end
end

function Settings:get(key)
  return self.config[string.lower(key)]
end

function Settings:isLocal()
  return self.config["local"] == "true"
end

function Settings:verbose()
  return self.config.verbose == "true"
end

function Settings:check()
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("mkdir -p " .. self.config[global.loadgenWd])
  cmd:execute(false)
end

function Settings:print()
  printBar()
  show("Settings:")
  local t = {}
  for key,value in pairs(self.config) do
    table.insert(t,key)
  end
  table.sort(t)
  for i,name in pairs(t) do
    show(string.format("     %-20s = %s", name, self.config[name]))
  end
  show()
end
  