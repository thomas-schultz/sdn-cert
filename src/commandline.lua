CommandLine = {}
CommandLine.__index = CommandLine


function CommandLine.getRunInstance(islocal)
  if (islocal == true) then return CommandLine.create()
  else return CommandLine.createssh() end
end

function CommandLine.create(...)
  local self = setmetatable({}, CommandLine)
  self.commands = {}
  self.ssh = false
  self.background = false
  self:add(...)
  return self
end

function CommandLine.createssh(...)
  local self = setmetatable({}, CommandLine)
  self.commands = {}
  self.ssh = true
  self.background = false
  local line = "ssh root@" .. settings:get(global.loadgen_host) .. " \""
  table.insert(self.commands, line)
  self:add(...)
  return self
end

function CommandLine.createBackground(...)
  local self = setmetatable({}, CommandLine)
  self.commands = {}
  self.ssh = false
  self.background = true
  self:add(...)
  return self
end

function CommandLine:add(...)
  local args = {...}
  if (not args or #args == 0) then return end
  local line = ""
  for i,arg in ipairs(args) do line = line .. arg .. " " end
  line = string.trim(line)
  if (not self.background) then
    table.insert(self.commands, line .. "; ")
  else
    table.insert(self.commands, line .. " & ")
  end
end

function CommandLine:get()
  local line = ""
  for i,str in pairs(self.commands) do
    line = line .. str
  end
  line = string.trim(line)
  if (self.ssh) then line = line .. "\"" end
  return line
end

function CommandLine:print(cmd)
  showIndent(self:get())
end

function CommandLine:execute(output)
  output = output ~= nil or output
  if (settings.config.simulate or output == true) then
    return self:capture(false)
  end
  os.execute(self:get())
end

function CommandLine:capture(result)
  result = result == nil or result
  local out = nil
  if settings.config.simulate then
    show("  " .. self:get())
  else
    local handle = io.popen(self:get() .. " 2>&1")
    out = handle:read("*a")
  end
  if (result) then return out end
end