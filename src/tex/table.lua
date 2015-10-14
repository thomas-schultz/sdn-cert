TexTable = {}
TexTable.__index = TexTable

function TexTable.create(spec, pos)
  local self = setmetatable({}, TexTable)
  self.header = {}
  
  self.control = {}
  self.data = {}
  
  self:setPos(pos)
  self:setSpec(spec)
  return self
end

function TexTable:setPos(pos)
  if (pos) then self.header.pos = "[" .. pos .. "]"
  else  self.header.pos = "" end
end

function TexTable:setSpec(spec)
  if (spec) then self.header.spec = "{" .. spec .. "}"
  else  self.header.spec = "" end
end

function TexTable:add(...)
  local args = {...}
  local line = ""
  if (#self.data == 0) then line = "\\hline\n" end
  for i,value in pairs(args) do
    value = string.replaceAll(value, "_", "\\_") 
    line = line .. value
    if (i < #args) then line = line .. " & "
    else line = line .. " \\\\ \\hline" end
  end
  table.insert(self.data, line)
end

function TexTable:getTex()
  local tex = "\\begin{center}\n"
  tex = tex .. "\\begin{tabular}" ..  self.header.pos ..  self.header.spec .. "\n"
  for i=1,#self.data do
    tex = tex .. self.data[i] .. "\n"
  end
  tex = tex .. "\\end{tabular}\n"
  tex = tex .. "\\end{center}"
  return(tex)
end