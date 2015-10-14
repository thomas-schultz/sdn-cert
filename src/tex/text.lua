TexText = {}
TexText.__index = TexText

function TexText.create()
  local self = setmetatable({}, TexText)
  self.lines = {}
  return self
end

function TexText:add(...)
  local args = {...}
  for i,line in pairs(args) do
    line = string.replaceAll(line, "_", "\\_")
    table.insert(self.lines, line)
  end
end

function TexText:getTex()
  local tex = ""
  for i=1,#self.lines do
    tex = tex .. self.lines[i] .. "\n"
  end
  return(tex)
end