#!/usr/bin/env lua

--[[

This script can be called from any benchmark config. It needs at least 6 arguments:
  loop_count:         specifies how many iterations will be done
  loop_value:         specifies which argument will be changed
  loop_action:        change between two iterations; [+-*/^][0..9]* e.g. +1
  of_script:          OpenFlow script to call
  ip:                 sdn-device ip
  port:               sdn-device port
  args[] (optional):  parameter will be passed to the of_script in the same order

]]

folder = "./benchmark-files/"
config = {}
args   = {}
count  = 1

function sleep(s)
  local ntime = os.time() + s
  repeat until os.time() > ntime
end

function loop()
  local monitor = "sudo ovs-ofctl monitor tcp:" .. config.ip .. ":" .. config.port .. " 128 2>&1"
  local stop    = "sudo pkill -SIGINT ovs-ofctl 2>&1"

  --start monitor
  local handle = io.popen(monitor)
  run()
  while(count < config.loop_count) do
    local out = handle:read("*l")
    if (out) then
      if (string.find(out, "NXT_PACKET_IN")) then next() end
    else
      sleep(1)
    end 
  end
  --stop monitor
  local handle = io.popen(stop)
  handle:close()
end

function next()
  applyAction()
  count = count + 1
  run()
end

function run()
  local cmd = config.script .. " " ..  config.ip .. " " .. config.port
  for i=1,#args do
    cmd = cmd .. " " .. args[i]
  end
  os.execute(cmd)
end

function applyAction()
  local op = string.sub(config.loop_action,1,1)
  local num = string.sub(config.loop_action,2,-1)
  local switch = {
    ["+"] = function (val, mod) return val + mod end,
    ["-"] = function (val, mod) return val - mod end,
    ["*"] = function (val, mod) return val * mod end,
    ["/"]  = function (val, mod) return val / mod end,
    ["^"] = function (val, mod) return math.pow(val,mod) end,
  }
  local func = switch[op]
  if (func == nil) then return end
  args[config.loop_value] = func(args[config.loop_value], num)
end

function main()
  if (#arg < 6) then 
    print("Usage loop_count loop_value loop_action of_script ip port [args]")
    return
  end
  config.loop_count   = tonumber(arg[1])
  config.loop_value   = tonumber(arg[2])
  config.loop_action  = arg[3]
  config.script       = folder .. arg[4]
  config.ip           = arg[5]
  config.port         = arg[6]
  for i=7,#arg do
    table.insert(args, i-6, arg[i])
  end
  loop()
end

main()