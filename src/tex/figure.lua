TexFigure = {}
TexFigure.__index = TexFigure

function TexFigure.create(pos)
  local self = setmetatable({}, TexFigure)
  self.header = {}
  self.data = {}
  self:setPos(pos)
  return self
end

function TexFigure:setPos(pos)
  if (pos) then self.header.pos = "[" .. pos .. "]"
  else  self.header.pos = "" end
end

function TexFigure:add(...)
  local args = {...}
  for i,value in pairs(args) do
    table.insert(self.data, value)
  end
end



function TexFigure:getTex()
  local tex = "\\begin{figure}" ..  self.header.pos .. "\n"
  tex = tex .. "\\pgfplotsset{compat=1.10}\n\\begin{center}\n"
  for i=1,#self.data do
    tex = tex .. self.data[i] .. "\n"
  end
  tex = tex .. "\\end{center}\n"
  tex = tex .. "\\end{figure}"
  return(tex)
  
  
end