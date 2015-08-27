ArgParser = {}
ArgParser.__index = ArgParser


function ArgParser.create()
  local self = setmetatable({}, ArgParser)
  self.name = {}
  self.opts = {}
  self.optval = {}
  self.desc = {}
  self.args = {}
  return self
end

function ArgParser:addOption(opt, desc)
  local str = opt
  local optarg = string.find(opt, "=")
  if not (optarg) then optarg = 0 end
  opt = string.sub(opt,1,optarg-1)
  self.opts[opt] = false
  self.name[opt] = str
  self.desc[opt] = desc
end

function ArgParser:parse(args)
  local isopt = true
  local arg_count = 0
  for i=1,#args do
    local arg = args[i]
    if (isopt) then
      isopt = false
      local optarg = string.find(arg, "=")
      local optval = nil
      if (optarg) then
        -- option with value '(-/--)opt=value'
        optval = string.sub(arg,optarg+1,-1)
      else
        -- simple option '(-/--)opt'
        optarg = 0
      end
      local opt_codes = {"-", "--"}
      for i,code in pairs(opt_codes) do
         if (string.sub(arg,1,#code) == code) then
          local opt = code .. string.sub(arg,#code+1,optarg-1)
          if (self.opts[opt] == false or self.opts[opt] == true) then
            self.opts[opt] = true
            self.optval[opt] = optval
          else
            print("unknown option '" .. opt .. "'")
            return
          end
          isopt = true            
        end
      end
    end
    if (not isopt) then
      arg_count = arg_count + 1
      table.insert(self.args, arg_count, arg)
    end 
  end
end

function ArgParser:hasOption(opt)
  return self.opts[opt]
end

function ArgParser:getOptionValue(opt)
  return self.optval[opt]
end

function ArgParser:getArgCount()
  return #self.args
end

function ArgParser:getArg(index)
  return self.args[index]
end

function ArgParser:printHelp()
  print("Usage: ./run.sh <benchmark-file>")
  for opt in pairs(self.opts) do
    local str = string.format("%-24s %s", self.name[opt], self.desc[opt])
    print(str)
  end
end
