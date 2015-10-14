FileContent = {}
FileContent.__index = FileContent

function FileContent.create(file)
  local self = setmetatable({}, FileContent)
  self.file = file
  self.lines = {}
  return self
end

function FileContent:getFileName()
  self.type = self.type or ".out"
  self.file = self.file or "data_" .. string.sub(tostring(self), 8, -1)
  return self.file .. self.type
end

function FileContent:addCsvFile(data, noHeader)
  if (not data) then return end
  self.type = ".csv"
  local dataFile = io.open(data, "r")
  if (not dataFile) then return end
  if (noHeader) then dataFile:read() end
  if (not dataFile) then return end
  while (true) do
    local line = dataFile:read()
    if (line == nil) then break end
    table.insert(self.lines, line)
  end
  io.close(dataFile)
end

function FileContent:addCsvLine(line)
  self.type = ".csv"
  if (line) then table.insert(self.lines, line) end
end

function FileContent:getTex()
  local tex = "\\begin{filecontents*}{".. self:getFileName() .. "}\n"
  for i=1,#self.lines do
    tex = tex .. self.lines[i] .. "\n"
  end
  tex = tex .. "\\end{filecontents*}"
  return(tex)
end