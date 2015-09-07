CommandLine = {}
CommandLine.__index = CommandLine

function CommandLine.getRunInstance(islocal)
  if (islocal == true) then return CommandLine
  else return SSHCommand end
end

function CommandLine.create(cmdline)
  local self = setmetatable({}, CommandLine)
  self.commands = {}
  if (cmdline) then self:addCommand(cmdline) end
  return self
end

function CommandLine:addCommand(cmd)
  table.insert(self.commands, cmd)
end

function CommandLine:get()
  local line = ""
  for i,cmd in pairs(self.commands) do
    line = line .. cmd .. " 2>&1; "
  end
  return string.trim(line)
end

function CommandLine:print()
  show(self:get())
end

function CommandLine:sendToBackground()
   os.execute(string.replaceAll(self:get(), ";", "&"))
end

function CommandLine:execute(verbose)
  if (not self:get()) then
    printlog_err("Cannot execute empty command line") return end
  verbose = verbose ~= nil and verbose
  local out = nil
  if (settings.config.simulate) then
    show("  " .. self:get())
  else
    local handle = io.popen(self:get())
    out = ""
    while (true) do
      local line = handle:read("*l")
      if (not line) then break end
      out = out .. line .. "\n"
      if (verbose and string.len(line) > 0) then print(line) end
    end
    log_debug("Running " .. self:get() .. "\n" .. out)
  end
  return out
end

function CommandLine:tryExecute(errors, verbose)
  local ret = self:execute(verbose)
  if (not ret) then return end
  for err,msg in pairs(errors) do
    if (string.find(ret, err)) then
      printlog_err(msg)
      log_debug(ret)
      exit()
    end
  end
  return ret
end




SSHCommand = {}
SSHCommand.__index = SSHCommand

SSHCommand.errors = {
  ["REMOTE HOST IDENTIFICATION HAS CHANGED"] = "WARNING: Remote host identification has changed, check your ssh config!",
  ["No route to host"] = "Host is not responding, check connection, ip and port!"
}

function SSHCommand.create(user, host)  
  local self = setmetatable({}, SSHCommand)
  self.commands = {}
  if (not user or not host) then 
    user = "root"
    host = settings:get(global.loadgenHost)
  end  
  self.line = "ssh " .. user .. "@" .. host
  return self
end

function SSHCommand:addCommand(cmd)
  table.insert(self.commands, cmd)
end

function SSHCommand:get()
  local line = self.line .. " \""
  for i,cmd in pairs(self.commands) do
    line = line .. cmd .. "; "
  end
  line = string.trim(line) .. "\""
  return line
end

function SSHCommand:print()
  show(self:get())
end

function SSHCommand:execute(verbose)
  verbose = verbose ~= nil and verbose
  local cmd = CommandLine.create(self:get())
  return cmd:tryExecute(SSHCommand.errors, verbose)
end




SCPCommand = {}
SCPCommand.__index = SCPCommand

SCPCommand.errors = {
  ["No such file or directory"] = "No such file or directory",
}

function SCPCommand.create(user, host)
  local self = setmetatable({}, SCPCommand)
  if (not user) then self.user = "root"
  else self.user = user end
  if (not host) then self.host = settings:get(global.loadgenHost)
  else self.host = host end 
  return self
end

function SCPCommand:switchCopyTo(isLocal, file, dst)
  if (isLocal) then self:copyLocal(file, dst)
  else self:copyToHost(file, dst) end
end

function SCPCommand:switchCopyFrom(isLocal, file, dst)
  if (isLocal) then self:copyLocal(file, dst)
  else self:copyFromHost(file, dst) end
end

function SCPCommand:copyLocal(file, dst)
  self.line = "scp " .. file .. " " .. dst
end

function SCPCommand:copyToHost(file, dst)
  if (not self.user or not self.host) then
    printlog_err("Missing user or host field") return end
  self.line = "scp " .. file .. " " .. self.user .. "@" .. self.host .. ":" .. dst
end

function SCPCommand:copyFromHost(file, dst)
  if (not self.user or not self.host) then
    printlog_err("Missing user or host field") return end
  self.line = "scp " .. self.user .. "@" .. self.host .. ":" .. file .. " " .. dst
end

function SCPCommand:get()
  if (not self.line) then
    printlog_err("Invalid scp command") return end
  return self.line
end

function SCPCommand:print()
  show(self:get())
end

function SCPCommand:execute(verbose)
  verbose = verbose ~= nil and verbose
  local cmd = CommandLine.create(self:get())
  return cmd:tryExecute(SCPCommand.errors, verbose)
end

