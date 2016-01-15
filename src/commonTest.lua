CommonTest = {}
CommonTest.__index = CommonTest

--------------------------------------------------------------------------------
--  superclass for arbitrary tests
--------------------------------------------------------------------------------

--- Creates a new CommonTest.
function CommonTest.create()
  local self = setmetatable({}, CommonTest)
  return self
end

--- Prints all data from the the configuration. If dump is specified,
-- the output is written to this file
function CommonTest.print(config, dump)
  local t = {}
  for key,value in pairs(config) do
    table.insert(t,key)
  end
  table.sort(t)
  local out = ""
  for i,key in pairs(t) do
    local value = config[key]
    out = string.format("%s    %-20s = %s\n", out, key, tostring(value))
  end   
  if (dump) then
    local file = io.open(dump, "w")
    file:write(out)
  else logger.print(out) end
end

--- Exports all data from the the configuration. If dump is specified,
-- the output is written to this file
function CommonTest.export(config, dump)
  local t = {}
  for key,value in pairs(config) do
    table.insert(t,key)
  end
  table.sort(t)
  local keys = ""
  local values = ""
  for i,key in pairs(t) do
    keys = keys .. key .. ", "
    values = values .. config[key] .. ", "
  end
  keys = string.sub(keys,1,#keys-2)
  values = string.sub(values,1,#values-2)
  if (dump) then
    local file = io.open(dump, "w")
    file:write(keys .. "\n")
    file:write(values .. "\n")
  else
    show("  " .. keys)
    show("  " .. values)
  end
end

--- Parsing function to read in arguments from a configuration file.
-- Lists are parsed with commas or spaces. Data can be stored in
-- existing table t otherwise a new one is created.
function CommonTest.readInArgs(args, t)
  if (type(args) == 'string') then
    args = string.replaceAll(args, ", ", " ")
    args = string.replaceAll(args, ",", " ")
    args = string.split(args, " ")
  end
  local t = t or {}
  for n,arg in pairs(args) do
    --print("#", arg)
    local arg = string.trim(string.lower(arg))
    table.insert(t, n, arg)
  end
  return t 
end

--- Maps variables names to their values.
function CommonTest.mapArgs(test, args, type, asTable, isFeature)
  local asTable = asTable ~= nil and asTable
  local isFeature = isFeature ~= nil and isFeature
  if (not args) then return {} end
  local args = CommonTest.readInArgs(args)
  
  local line = ""
  for i=1,#args do
    local arg = args[i]
    local value = arg
    local isVar = string.find(arg, global.ch_var)
    if (isVar) then
      local key = string.replaceAll(string.sub(arg, 1, isVar-1) .. string.sub(arg, isVar+1, -1), "_", "")
      value = test.settings[string.replace(key, "=", "")]
      if (not value) then value = CommonTest.getLinks(test, arg, type, isFeature) end
      if (not value) then
        logger.err("Could not map variable '" .. key .. "' for '" .. test:getName() ..  "'")
        exit("Abort")
      end
    end
    line = line .. string.trim(tostring(value)) .. " "
    logger.debug(test:getName() .. ": mapped '" .. arg .. "' to '" .. value .. "'")
  end
  line = string.trim(line)
  if (asTable) then return string.split(line, " ")
  else return line end
end

--- Returns a list of link-ids from a given configuration string.
-- Checks if the numbers are possible or exceed the available link count. 
function CommonTest.getLinks(test, arg, type, isFeature)
  local isLink = string.find(arg, global.link)
  if (not isLink) then return nil end
  local linkId = CommonTest.checkLinkCount(test, arg, isFeature)
  if (linkId >= 0) then return tostring(settings.ports[linkId][type]) end
  local links = ""
  for n,link in pairs(settings.ports) do
    links = links .. tostring(link[type]) .. " "
  end
  return string.trim(links)
end

--- Checks if the numbers are possible or exceed the available link count.
function CommonTest.checkLinkCount(test, arg, isFeature)
  local msg = "Disabled test"
  if (isFeature) then msg = "Disabled feature" end
  if (string.find(arg, global.link .. "%*")) then return -1 end
  local linkId = tonumber(select(2, string.getKeyValue(arg)))
  if (linkId and linkId > #settings.ports) then
    local msg = msg or "Disabled test"
    logger.warn(msg .. " '" .. test:getName() .. "', link number out of range: " .. tostring(linkId) .. " of " .. tostring(#settings.ports))
    test.disabled = true
    return -1
  end
  return linkId
end

--- Reads the file-field of the configuration. Checks if the files are
-- existent in the according path.
function CommonTest.readInFiles(test, folder, files, isFeature)
  local msg = "Disabled test"
  local files = files or {}
  if (isFeature) then msg = "Disabled feature" end
  local filelist = test.config.files
  if (type(filelist) == 'string') then filelist = string.split(filelist, " ") end
  for n,file in pairs(filelist) do
    file = string.trim(file)
    if (not localfileExists(folder .. "/" .. file)) then
      logger.print(msg .. " '" .. test:getName() .. "', missing file '" .. file .. "'", "WARN")
      test.disabled = true
    else
      table.insert(files, file)
      test.settings["file" .. tonumber(n)] = settings:get(global.loadgenWd) .. "/" .. global.scripts .. "/" .. file
    end
  end
  return files
end

return CommonTest
