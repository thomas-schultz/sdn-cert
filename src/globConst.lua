Global = {}
Global.__index = Global

global = {}

  global.headline1 = "bold"
  global.headline2 = "white"

  global.configFile       = "settings.cfg"
  global.featureList      = "feature_list.cfg"
  global.featureFile      = "features.cfg"
  global.benchmarkCfgs    = "benchmark-configs"
  global.benchmarkFolder  = "benchmark-files"
  global.featureFolder    = "feature-tests"
  global.tempdir          = "/tmp"
  
  global.moongenRepo      = "https://github.com/emmericp/MoonGen"
  global.ofVersion        = "openflow"
  
  -- logger
  global.logFile = "sdn-cert.log"
  
  -- path settings
  global.results = "results"
  global.archive = "archive"
  global.scripts = "scripts"
  global.timeout = 2
  
  -- Keywords are stored lower-case and without underscore
  
  --settings.cfg keywords:
  global.loadgenHost = "loadgenhost"
  global.loadgenWd   = "loadgenwd"
  global.switchIP    = "switchip"
  global.switchPort  = "switchport"
  global.phyLinks    = "links"
  
  --benchmark keywords
  global.cfgFiletype     = ".cfg"
  global.requires        = "require"
  global.prepare         = "prepare"
  global.name            = "name"
  global.loopCount       = "loops"
  global.duration        = "duration"
  global.loadgen         = "loadGen"
  global.lgArgs          = "lgArgs"
  global.copy_files      = "files"
  global.link            = "link"
  global.state           = "state"
  
  --special characters
  global.ch_var     = "%$"
  global.ch_comment = "#"
  global.ch_equal   = "="
  global.ch_connect = "-"
 
  global.featureState = {
    required    = "required",
    optional    = "optional",
    recommended = "recommended",
    undef       = "undefined",
  }
  
  
  global.default_cfg = [[
        # settings file
        
        # Debugging settings
        #debug = true
        
        OpenFlowVersion = OpenFlow10
        
        # set to true if this host is the load-generator
        local = true
        # ip,name or ssh alias of load-generator host, ignored if local is true
        loadgenHost = 127.0.0.1
        # working directory on load-gen
        loadgenWd = /root/tmp
        
        # switch configuration
        switchIP = 127.0.0.1
        switchPort = 6633
        
        # physical phyLinks between switch and load-generator
        Links = switch-MoonGen
  ]]
  
  return global
