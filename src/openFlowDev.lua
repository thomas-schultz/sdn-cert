OpenFlowDevice = {}
OpenFlowDevice.__index = OpenFlowDevice


function OpenFlowDevice.create(ip, port, version)
  local self = setmetatable({}, OpenFlowDevice)
  self.ip      = ip or "127.0.0.1"
  self.port    = tostring(port) or "6633"
  self.version = version or settings.config[global.ofVersion]
  self.bridge  = "tcp:" .. self.ip .. ":" .. self.port
  self.target  = self.bridge .. " -O " .. self.version
  return self
end

function OpenFlowDevice:reset()
  local cmd = CommandLine.create("ovs-ofctl del-flows " .. self.target)
  if (compareVersion("OpenFlow11", self.version) >= 0) then
  cmd:addCommand("ovs-ofctl del-groups " .. self.target) end
  if (compareVersion("OpenFlow13", self.version) >= 0) then
  cmd:addCommand("ovs-ofctl del-meters " .. self.target) end
  cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:dumpFlows(version)
  version = version or self.version
  local cmd = CommandLine.create("ovs-ofctl dump-flows " .. self.bridge .. " -O " .. version)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:dumpGroups(version)
  version = version or self.version
  if (compareVersion("OpenFlow11", self.version) < 0) then return "groups are not supported in " .. self.version end
  local cmd = CommandLine.create("ovs-ofctl dump-groups " .. self.bridge .. " -O " .. version)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:dumpMeters(version)
  version = version or self.version
  if (compareVersion("OpenFlow13", self.version) < 0) then return "meters are not supported in " .. self.version end
  local cmd = CommandLine.create("ovs-ofctl dump-meters " .. self.bridge .. " -O " .. version)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:dumpAll(dump)
  local ret = "Flow dump:\n" .. self:dumpFlows() .. "\n\n"
  if (compareVersion("OpenFlow11", self.version) >= 0) then
    ret = ret .. "Group dump:\n" .. self:dumpGroups() .. "\n\n" end
  if (compareVersion("OpenFlow13", self.version) >= 0) then
    ret = ret .. "Meter dump:\n" .. self:dumpMeters() end
  if (not dump) then return ret end
  local dunpFile = io.open(dump, "w")
  dunpFile:write(ret)
  io.close(dunpFile)
  return ret
end

function OpenFlowDevice:installFlow(flow)
  local cmd = CommandLine.create("ovs-ofctl add-flow " .. self.target ..  "\"" .. flow .. "\"")
  log_debug = (cmd:get())
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installFlows(file)
  if (not absfileExists(file)) then printlog_err("Cannot add flows, no such file: '" .. file .. "'") return end
  local cmd = CommandLine.create("ovs-ofctl add-flows " .. self.target .. " " .. file)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installGroup(group)
  local cmd = CommandLine.create("ovs-ofctl add-group " .. self.target ..  "\"" .. group .. "\"")
  log_debug = (cmd:get())
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installGroups(file)
  if (not absfileExists(file)) then printlog_err("Cannot add groups, no such file: '" .. file .. "'") return end
  local cmd = CommandLine.create("ovs-ofctl add-groups " .. self.target .. " " .. file)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installMeter(group)
  local cmd = CommandLine.create("ovs-ofctl add-group " .. self.target ..  "\"" .. group .. "\"")
  log_debug = (cmd:get())
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installMeters(file)
  if (not absfileExists(file)) then printlog_err("Cannot add meters, no such file: '" .. file .. "'") return end
  local cmd = CommandLine.create("ovs-ofctl add-meters " .. self.target .. " " .. file)
  return cmd:execute(settings.config.cervose)
end

function OpenFlowDevice:installAllFiles(file, dump)
  local ret = ""
  if (compareVersion("OpenFlow13", self.version) >= 0 and absfileExists(file .. ".meters")) then
    ret = ret .. "install meters file:\n" .. self:installMeters(file .. ".meters") .. "\n" end
  if (compareVersion("OpenFlow11", self.version) >= 0 and absfileExists(file .. ".groups")) then
    ret = ret .. "install group file:\n" ..  self:installGroups(file .. ".groups") .. "\n" end
  ret = ret .. "install flow file:\n" .. self:installFlows(file .. ".flows") .. "\n"
  if (not dump) then return ret end
  local dunpFile = io.open(file .. dump, "w")
  dunpFile:write(ret)
  io.close(dunpFile)
  return ret
end


function OpenFlowDevice:createFlowData(data, file)
  local stream = io.open(file, "w")
  if (data) then for i,line in pairs(data) do stream:write(line .. "\n") end end
  io.close(stream)
end

function OpenFlowDevice:createFlowFile(flows, file)
   file = file .. ".flows" or global.tempdir .. "/switch.flows"
  return self:createFlowData(flows, file)
end

function OpenFlowDevice:createGroupFile(groups, file)
  file = file .. ".groups" or global.tempdir .. "/switch.groups"
  return self:createFlowData(groups, file)
end

function OpenFlowDevice:createMeterFile(meters, file)
  file = file .. ".meters" or global.tempdir .. "/switch.meters"
  return self:createFlowData(meters, file)
end

function OpenFlowDevice:createAllFiles(flowData, file)
  self:createFlowFile(flowData.flows, file)
  if (#flowData.groups > 0 and compareVersion("OpenFlow11", self.version) >= 0) then
    self:createGroupFile(flowData.groups, file) end
  if (#flowData.meters > 0 and compareVersion("OpenFlow13", self.version) >= 0) then
    self:createMeterFile(flowData.meters, file) end
end

function OpenFlowDevice:getBenchmarkFlows(name, ...)
  local benchConf = require "benchmark_config"
  local flowData = {flows  = {}, groups = {}, meters = {} }
  local addflows = benchConf[name]
  if (not addflows) then
    printlog_err("Failed to create flow entries for test '" .. name .. "'")
  else
      addflows(flowData, ...) 
  end
  return flowData
end

function OpenFlowDevice:getFeatureFlows(name, ...)
  local featureConf = require "feature_config"
  local config = featureConf.feature[name]
  local flowData = {flows  = {}, groups = {}, meters = {} }
  local addflows = config.flowEntries
  if (not addflows) then
    printlog_err("Failed to create flow entries for feature test '" .. name .. "'")
    return flowData
  end
  addflows(flowData, ...)
  featureConf.feature.default.flowEntries(flowData)
  return flowData
end

