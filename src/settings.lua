Settings = {}
Settings.__index = Settings
        
function Settings.create(config_file)
  local self = setmetatable({}, Settings)
  self.config = {}
  self:readSettings(config_file)
  return self
end

-- read in the settings file
function Settings:readSettings(config_file)
  local f = io.popen("pwd 2>&1")
  self.config.local_path = f:read("*line")
  local fh = io.open(config_file)
  self.config.localPath    = "."
  self.config.verbose       = false
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
  if (self:isLocal()) then self.config[string.lower(global.loadgen_host)] = nil end
  if (self.config[global.loadgen_wd] == nil) then self.config[global.loadgen_wd] = "/tmp" end
  self.ports = {}
  for n,connection in pairs(string.split(self:get(global.connection), ",")) do
    local split = string.find(connection, global.ch_connect)
    local of_port = tonumber(string.sub(connection, 1, split-1))
    local lg_port = tonumber(string.sub(connection, split+1, -1))
    if (of_port == nil or lg_port == nil) then
      printlog("Invalid connection: '" .. connection .. "'")
      exit()
    end
    self.ports[n] = {}
    self.ports[n].of = of_port
    self.ports[n].lg = lg_port
    log_debug("added port " .. of_port .. global.ch_connect .. lg_port)
  end
  if (#self.ports == 0) then
    printlog("Invalid settings, no connections are assigned")
    exit()
  end
  if (#self.ports == 1) then
    printlog_warn("You have configured only a single connection. Most of the features require at least two!")
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
  cmd:addCommand("mkdir -p " .. self.config[global.loadgen_wd])
  cmd:execute(false)
end

function Settings:print()
  printBar()
  show("Settings:")
  for key,value in pairs(self.config) do
    show(string.format("  %-16s = %s", key, tostring(value)))
  end
end
  