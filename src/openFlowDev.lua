OpenFlowDevice = {}
OpenFlowDevice.__index = OpenFlowDevice

package.path = package.path .. ';feature-tests/?.lua'

function OpenFlowDevice.create(ip, port, version)
  local self = setmetatable({}, OpenFlowDevice)
  if (not ip) then ip = "127.0.0.1" end
  if (not port) then port = "6633" end
  if (not version) then version = settings.config[global.ofVersion] end
  self.ip = ip
  self.port = port
  self.bridge = "tcp:" .. self.ip .. ":" .. self.port
  self.version = version
  return self
end

function OpenFlowDevice:reset()
  local cmd = CommandLine.create("ovs-ofctl del-flows " .. self.bridge)
  if (compareVersion("OpenFlow11", self.version) >= 0) then
  cmd:addCommand("ovs-ofctl del-groups " .. self.bridge .. " -O OpenFlow11") end
  if (compareVersion("OpenFlow13", self.version) >= 0) then
  cmd:addCommand("ovs-ofctl del-meters " .. self.bridge .. " -O OpenFlow13") end
  cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:dumpFlows(version)
  if (not version) then version = settings.config[global.ofVersion] end
  local cmd = CommandLine.create("ovs-ofctl dump-flows " .. self.bridge .. " -O " .. version)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installFlow(flow)
  local cmd = CommandLine.create("ovs-ofctl add-flow " .. self.bridge .. "\"" .. flow .. "\"")
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installFlows(file)
  if (not absfileExists(file)) then print_err("Cannot add flows, no such file: '" .. file .. "'") return end
  local cmd = CommandLine.create("ovs-ofctl add-flows " .. self.bridge .. " " .. file)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:createFlowFile(flows, file)
  local path = global.tempdir .. "/flows.ovs"
  if (file) then path = file end  
  local file = io.open(path, "w")
  for i,flow in pairs(flows) do
    file:write(flow .. "\n")
  end
  io.close(file)
  return path
end

function OpenFlowDevice:getFeatureFlows(name, ...)
  local featureConf = require "feature_config"
  local config = featureConf.feature[name]
  local flows = {}
  local addflows = config.flowEntries
  if (not addflows) then
    printlog_err("Failed to create flow entries for feature test '" .. name .. "'")
    return flows
  end
  addflows(flows, ...)
  featureConf.feature.default.flowEntries(flows)
  return flows
end
