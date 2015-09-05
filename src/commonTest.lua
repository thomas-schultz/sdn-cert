CommonTest = {}
CommonTest.__index = CommonTest

function CommonTest.getArgs(args, config, asTable)
  asTable = asTable ~= nil and asTable
  local t = {}
  for i=1,#args do
    local arg = args[i]
    local isvar = string.find(arg, global.ch_var)
    if isvar then
      local key = string.sub(arg, 1, isvar-1) .. string.sub(arg, isvar+1, -1)
      local value = config[string.replaceAll(key, "_", "")]
      if (not value) then printlog_err("Could not map variable '" .. key .. "'")
      else t[i] = value end
    else
     t[i] = arg
    end
  end
  if (asTable) then return t end
  local line = ""
  if (#t == 0) then return line end
  for i=1,#t do
    line = line .. t[i] .. " "
  end
  return string.trim(line)
end

function CommonTest.checkLinkCount(feature, arg)
  local con_count = tonumber(select(2, string.getKeyValue(arg)))
  if (con_count and con_count > #settings.ports) then
    printlog_warn("Disabled feature '" .. feature:getName() .. "', not enough phyLinks: " .. tostring(con_count) .. " of " .. tostring(#settings.ports))
    feature.disabled = true
  end
end

function CommonTest.readInArgs(test, key, arg_table, type)
  for n,of_arg in pairs(string.split(test:get(key), ",")) do
    local arg = string.trim(string.lower(of_arg))
    if (string.find(arg, global.link)) then
      CommonTest.checkLinkCount(test, arg)
      arg = string.replace(arg, global.link, type..global.link)
    end
    arg = string.replace(arg, global.ch_equal, "")
    table.insert(arg_table, n, arg)
  end
end

function CommonTest.readInPrepArgs(test)
  CommonTest.readInArgs(test, global.requires, test.require, "of")
end


function CommonTest.readInOfArgs(test)
  CommonTest.readInArgs(test, global.ofArgs, test.of_args, "of")
end

function CommonTest.readInLgArgs(test)
  CommonTest.readInArgs(test, global.lgArgs, test.lg_args, "lg")
end

function CommonTest.readInFiles(test, msg)
  for n,file in pairs(string.split(test:get(global.copy_files), ",")) do
    file = string.trim(file)
    if (not localfileExists(global.featureFolder .. "/" .. file)) then
      log_warn(msg .. " '" .. test:getName() .. "', missing file '" .. file .. "'")
      test.disabled = true
    else
      table.insert(test.files, n, file)
      test.config["file" .. tonumber(n)] = settings:get(global.loadgenWd) .. "/" .. global.scripts .. "/" .. file
    end
  end
end

function CommonTest.setLinks(test)
  test.config.ip = settings:get(global.switchIP)
  test.config.port = settings:get(global.switchPort)
  local lg = ""
  local of = ""
  for n=1,#settings.ports do
    of = of .. " " .. settings.ports[n].of
    lg = lg .. " " .. settings.ports[n].lg
    test.config[global.ofLinks .. tostring(n)] = settings.ports[n].of
    test.config[global.lgLinks .. tostring(n)] = settings.ports[n].lg
  end
  test.config[global.ofLinks .. "*"] = string.trim(of)
  test.config[global.lgLinks .. "*"] = string.trim(lg)
end

function CommonTest.setSwitch(test)
  test.config.ip = settings:get(global.switchIP)
  test.config.port = settings:get(global.switchPort)
end


function CommonTest.normalizeKey(key)
  return string.replaceAll(string.lower(key), "_", "")
end

function CommonTest.print(name, config)
  show("  " .. name)
  local t = {}
  for key,value in pairs(config) do
    table.insert(t,key)
  end
  table.sort(t)
  for i,name in pairs(t) do
    show(string.format("     %-20s = %s", name, tostring(config[name])))
  end
  show()
end