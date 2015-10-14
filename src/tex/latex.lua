TexElement = {}
TexElement.__index = TexElement


function TexElement.create(name, option)
  local self = setmetatable({}, TexElement)
  self.name = name
  self.option = option
  self.control = {}
  self.content = {}
  return self
end

function TexElement:setOption(option)
  self.option = option
end

function TexElement:getOption(option)
  if (option) then return "[" .. option .. "]"
  else return "" end
end

function TexElement:addControl(name, option)
  local t = {
    pre = "\\begin" .. self:getOption(option) .. "{" .. name .."}",
    post = "\\end{" .. name .."}",
  }
  table.insert(self.control, t)
end

function TexElement:getControl(control, type)
  if (control[type]) then return control[type]
  else return "" end
end

function TexElement:getTex()
  local pre = "\\begin" .. self:getOption(self.option) .. "{" .. self.name .. "}"
  for i=1,#self.control do
     pre = pre .. "\n" .. self:getControl(self.control[i], "pre")
  end
  local tex = ""
  for i=1,#self.content do
    tex = tex .. self.content[i]:getTex() .. "\n\n"
  end
  local post = "\\end{" .. self.name .. "}"
  for i=1,#self.control do
     post = self:getControl(self.control[i], "post") .. "\n" .. post
  end
  return(pre .. "\n" .. tex .. "\n" .. post)
end
