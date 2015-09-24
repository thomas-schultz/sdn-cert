CommonTest = {}
CommonTest.__index = CommonTest

function CommonTest.create()
  local self = setmetatable({}, CommonTest)
  return self
end


function CommonTest.print(name, config, dump)
  local t = {}
  for key,value in pairs(config) do
    table.insert(t,key)
  end
  table.sort(t)
  local out = name
  for i,key in pairs(t) do
    local value = config[key]
    out = out .. string.format("\n     %-20s = %s", key, tostring(value))
  end   
  if (dump) then
    local file = io.open(dump, "w")
    dump:write(out)
  else show("  " .. out) end
end

function CommonTest.readInArgs(args, t)
  if (type(args) == 'string') then
    args = string.split(string.replaceAll(args, ",", " "), " ") end
  local t = t or {}
  for n,arg in pairs(args) do
    local arg = string.trim(string.lower(arg))
    table.insert(t, n, arg)
  end
  return t 
end

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
        printlog_err("Could not map variable '" .. key .. "' for '" .. test:getName() ..  "'")
        exit("Abort")
      end
    end
    line = line .. string.trim(tostring(value)) .. " "
    log_debug(test:getName() .. ": mapped '" .. arg .. "' to '" .. value .. "'")
  end
  line = string.trim(line)
  if (asTable) then return string.split(line, " ")
  else return line end
end

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

function CommonTest.checkLinkCount(test, arg, isFeature)
  local msg = "Disabled test"
  if (isFeature) then msg = "Disabled feature" end
  if (string.find(arg, global.link .. "%*")) then return -1 end
  local linkId = tonumber(select(2, string.getKeyValue(arg)))
  if (linkId and linkId > #settings.ports) then
    local msg = msg or "Disabled test"
    printlog_warn(msg .. " '" .. test:getName() .. "', link number out of range: " .. tostring(linkId) .. " of " .. tostring(#settings.ports))
    test.disabled = true
  end
  return linkId
end

function CommonTest.readInFiles(test, folder, files, isFeature)
  local msg = "Disabled test"
  local files = files or {}
  if (isFeature) then msg = "Disabled feature" end
  local filelist = test.config.files
  if (type(filelist) == 'string') then filelist = string.split(filelist, " ") end
  for n,file in pairs(filelist) do
    file = string.trim(file)
    if (not localfileExists(folder .. "/" .. file)) then
      printlog_warn(msg .. " '" .. test:getName() .. "', missing file '" .. file .. "'")
      test.disabled = true
    else
      table.insert(files, file)
      test.settings["file" .. tonumber(n)] = settings:get(global.loadgenWd) .. "/" .. global.scripts .. "/" .. file
    end
  end
  return files
end
