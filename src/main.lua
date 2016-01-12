#!/usr/bin/env lua

package.path = package.path .. ';src/?.lua'

global = require "globConst"

require "argParser"
require "benchmark"
require "commandline"
require "commonTest"
require "feature"
require "logger"
require "openFlowDev"
require "reports"
require "setup"
require "settings"
require "testcase"
require "tools/general"
require "tex/document"


settings = nil
debugMode = false

local function main()
  logger = Logger.init(global.logFile) 
  local f = io.open(global.configFile, "rb")  
  if f then f:close() else
    logger.printlog("Missing config file, created default")
    local file = io.open(global.configFile, "w")
    file:write(global.default_cfg)
    io.close(file)
  end
   
  settings = Settings.create(global.configFile)

  local parser = ArgParser.create()
  parser:addOption("--setup", "installs MoonGen")
  parser:addOption("--init", "initializes MoonGen")
  parser:addOption("--sim", "all operations are printed, instead of executed")
  parser:addOption("--eval", "only starts the evaluation process")
  parser:addOption("--nocolor", "disables the colored output")
  parser:addOption("--check", "checks if the test setup is correctly configured")
  parser:addOption("--tar", "creates a tar archive for the current and the final results folder")
  parser:addOption("--clean", "cleans the result folder")
  parser:addOption("--skipfeature", "skips all feature tests")
  parser:addOption("--testfeature=feature", "tests specific feature, nothing more will be done")
  parser:addOption("--verbose", "shows further information")
  parser:addOption("-O=OpenFlowVersion", "specifies the OpenFlow protocol version")
  parser:addOption("--help", "prints this help")
  
  parser:parse(arg)
  if (parser:hasOption("--help")) then parser:printHelp() exit() end
  if (parser:hasOption("--verbose")) then settings.config.verbose = true end
  if (parser:hasOption("--sim")) then settings.config.simulate = true end
  if (parser:hasOption("--nocolor")) then logger.disableColor() end
  if (parser:hasOption("--tar")) then Setup.archive() settings.config.archive = true end
  if (parser:hasOption("--eval")) then settings.config.evalonly = true settings.config.skipfeature = true end
  settings:verify()
    
  if (parser:hasOption("--init")) then Setup.initMoongen() end
  if (parser:hasOption("--setup")) then Setup.setupMoongen() end
  if (parser:hasOption("--check")) then settings.config.checkSetup = true end
  if (parser:hasOption("--clean")) then Setup.cleanUp() exit() end
  if (parser:hasOption("--skipfeature")) then settings.config.skipfeature = true end
  if (parser:hasOption("--testfeature")) then settings.config.testfeature = parser:getOptionValue("--testfeature") end
  if (parser:hasOption("-O")) then settings.config[global.ofVersion] = string.gsub(parser:getOptionValue("-O"), "%.", "") end
  
  if settings.config.simulate then 
    print("*******************\n* Simulation-Mode *\n*******************")
    logger.log("*** Simulation-Mode ***")
  end
  
  if (settings.config.checkSetup) then logger.log("Testing, if the setup is correctly configured") end 
  if (settings.config.skipfeature) then logger.log("Skipping feature test, requirements will be ignored") end
  if (settings.config.testfeature) then logger.log("Testing feature '" .. settings.config.testfeature .. "', nothing more will be done") end 
  
  if (parser:getArgCount() ~= 1) then
    if (parser:hasOption("--tar")) then
      exit()
    elseif (not settings.config.checkSetup and not settings.config.testfeature) then
      print("you need to specify a benchmark file!")
      exit()
    end
  end
  local benchmark_file = parser:getArg(1)
  if (not (settings.config.checkSetup  or settings.config.testfeature) and not localfileExists(benchmark_file)) then
    print("no such file '" .. benchmark_file .. "'")
    exit(1)
  end

  if ((not Setup.isReady() and not settings.config.simulate) or settings.config.checkSetup) then
    logger.printBar()
    exit()
  end

  local benchmark = Benchmark.create(benchmark_file)
  if (settings.config.verbose) then settings:print() end
  
  if (settings:evalOnly()) then
    benchmark:prepare()
    Reports.generate(benchmark)
    exit()
  end
  
  Setup.cleanUp()
  benchmark:testFeatures()
  benchmark:sumFeatures()
  benchmark:prepare()
  benchmark:run()
  Reports.generate(benchmark)
  
  if (settings:doArchive()) then Setup.archive() end
  
  logger.finalize()
end

main()
