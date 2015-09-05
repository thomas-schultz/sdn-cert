local error_messages = {
  openflow_fail     = "failes",
  openflow_socket   = "failed to connect to socket",
  moongen_hugepage  = "Cannot get hugepage information",
  moongen_bash      = "bash: ./moongen: No such file or directory",
  }
local string_matches = {
  openflow_port     = "port",
  openflow_port_delm = ":",
  moongen_devs       = "usable devices",
  moongen_lua_err    = "Lua error",
  moongen_build      = "Built target MoonGen",
  }

function acrhiveResults()
  printlog("Archive current results to " .. settings.config.localPath .. "/" .. global.archive)
  local cmd = CommandLine.create("mkdir -p " .. settings.config.localPath .. "/" .. global.archive)
  cmd:execute()
  local cmd = CommandLine.create("tar -cvf " .. settings.config.localPath .. "/" .. global.archive .. "/" .. global.results .. "_`date +%Y%m%d_%H%M%S`.tar " .. settings.config.localPath .. "/" .. global.results .. "/*")
  cmd:execute()
end

function setupMoongen()
  local cmd = nil
  if (settings:isLocal()) then cmd = CommandLine.create(settings.config.local_path .. "/tools/setup_MoonGen.sh " .. settings:get(global.loadgenWd) .. " " .. global.moongenRepo) 
  else cmd = CommandLine.create(settings.config.local_path .. "/tools/setup.sh " .. settings:get(global.loadgenHost) .. " " .. settings:get(global.loadgenWd) ..  " tools/") end
  cmd:execute(true)
  checkMoongen()
  exit()
end

function killMoongen()
  local kill = nil
  if (settings:isLocal()) then
    kill = CommandLine.create("pkill -f moongen")
  else
    kill = SSHCommand.create()
    kill:addCommand("pkill -f moongen")
  end
  kill:execute()
  kill:execute()
end

function initMoongen()
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand(settings:get(global.loadgenWd) .. "/MoonGen/build.sh")
  cmd:addCommand(settings:get(global.loadgenWd) .. "/MoonGen/setup-hugetlbfs.sh")
  local ret = cmd:execute(settings.config.verbose)
  if (settings.config.simulate) then exit() end
  if (ret and string.find(ret, string_matches.moongen_build)) then printlog("Building successful") 
  else printlog("Failed to initialize MoonGen") log_debug(ret) end  
  exit()
end

function checkOpenFlow()
  printBar()
  printlog("Checking test setup")
  local cmd = CommandLine.create("ovs-ofctl dump-ports tcp:" .. settings:get(global.switchIP) .. ":" .. settings:get(global.switchPort))
  local out = cmd:execute()
  if (out == nil or settings.config.simulate) then return false end
  if (string.find(out, error_messages.openflow_socket)) then
    show("OpenFlow device is not reachable!")
    printlog(out)
    return false
  elseif (string.find(out, error_messages.openflow_fail)) then
    show("OpenFlow device seem not to be ready!")
    printlog(out)
    return false
  else
    show("Available logical ports on the switch:")
    local ports = {}
    local find, find_ = string.find(out, "ports")
    if (not find) then return end
    out = string.sub(out, find_+1, -1)
    for n,p in pairs(string.split(out, "\n")) do
      local a = string.find(p, string_matches.openflow_port)
      local z = string.find(p, string_matches.openflow_port_delm)
      if (a and z) then
        local port = string.trim(string.sub(p, a+5, z-1))
        table.insert(ports, port)
      end
    end
    table.sort(ports)
    local list = ""
    for i,port in pairs(ports) do
      list = list .. port .. ", "
    end
    show("   " .. list)
    return true
  end 
end

function checkMoongen()
  killMoongen()
  local cmd = CommandLine.getRunInstance(settings:isLocal()).create()
  cmd:addCommand("cd " .. settings:get(global.loadgenWd).. "/MoonGen")
  cmd:addCommand("./moongen ls")
  local out = cmd:execute(false)
  if (out == nil or settings.config.simulate) then
    log_debug("Could not get output of MoonGen to detect available ports")
    return false
  end
  if (string.find(out, error_messages.moongen_hugepage)) then
    show("MoonGen is either running or not initialized, stop it or try '--init'")
    return false
  elseif (string.find(out, error_messages.moongen_bash)) then
    show("MoonGen seems not to be installed, try '--setup'")
    return false
  else
    show("Available physical devices of MoonGen:")
    local devs = string.find(out, string_matches.moongen_devs)
    local dev_term = string.find(out, string_matches.moongen_lua_err)
    if (not devs or not dev_term) then
      log_debug("Could not find MoonGen devices in output.\n" .. out)
      return false
    end
    out = string.sub(out, devs+#string_matches.moongen_devs+2, dev_term-2)
    show(out)
    return true
  end
end

function isReady()
  local result = checkOpenFlow()
  if (not result and not settings.config.simulate) then show("Make sure the OpenFlow device is configured appropriate and that the settings file contains valid values!") end
  result = checkMoongen() and result
  if (not result and not settings.config.simulate) then show("Make sure MoonGen is installed correctly") end
  return result
end