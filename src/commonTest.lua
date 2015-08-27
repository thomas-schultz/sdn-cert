CommonTest = {}
CommonTest.__index = CommonTest

function CommonTest.getArgs(args, config)
  local line = ""
  for i=1,#args do
    local arg = args[i]
    local isvar = string.find(arg, global.ch_var)
    if isvar then
      line = line .. (config[string.replaceAll(string.sub(arg, 1, isvar-1) .. string.sub(arg, isvar+1, -1), "_", "")]) .. " "
    else
     line = line .. arg .. " "
    end
  end
  return line
end

function CommonTest.checkConnectionCount(feature, arg)
  local con_count = tonumber(select(2, string.getKeyValue(arg)))
  if (con_count and con_count > #settings.ports) then
    printlog_warn("Disabled feature '" .. feature:getName() .. "', not enough connections: " .. tostring(con_count) .. " of " .. tostring(#settings.ports))
    feature.disabled = true
  end
end

function CommonTest.readInArgs(test, key, arg_table, type)
  for n,of_arg in pairs(string.split(test:get(key), ",")) do
    local arg = string.trim(string.lower(of_arg))
    if (string.find(arg, "con")) then
      CommonTest.checkConnectionCount(test, arg)
      arg = string.replace(arg, "con", type.."con")
    end
    arg = string.replace(arg, global.ch_equal, "")
    table.insert(arg_table, n, arg)
  end
end

function CommonTest.readInPrepArgs(test)
  CommonTest.readInArgs(test, global.requires, test.require, "of")
end


function CommonTest.readInOfArgs(test)
  CommonTest.readInArgs(test, global.openflow_script, test.of_args, "of")
end

function CommonTest.readInLgArgs(test)
  CommonTest.readInArgs(test, global.loadgen_arg, test.lg_args, "lg")
end

function CommonTest.setConnections(test)
  test.config.ip = settings:get(global.sdn_ip)
  test.config.port = settings:get(global.sdn_port)
  for n=1,#settings.ports do
    test.config[global.of_con .. tonumber(n)] = settings.ports[n].of
    test.config[global.lg_con .. tonumber(n)] = settings.ports[n].lg
  end
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
    show(string.format("     %-20s = %s", name, config[name]))
  end
  show()
end