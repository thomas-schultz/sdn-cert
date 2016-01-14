Global = {}
Global.__index = Global

global = {}

  --- output style 
  global.headline1 = "bold"
  global.headline2 = "white"

  --- path and file settings
  global.configFile       = "settings.cfg"
  global.featureList      = "feature_list.cfg"
  global.featureFile      = "features.cfg"
  global.benchmarkCfgs    = "benchmarks"
  global.benchmarkFolder  = "test-cases"
  global.featureFolder    = "feature-tests"
  global.tempdir          = "/tmp"
  global.cfgFiletype      = ".cfg"
  global.testLibrary     = "testcase_lib"
  global.featureLibrary  = "feature_config"
  
  --- MoonGen preferences
  global.moongenRepo      = "https://github.com/emmericp/MoonGen"
  global.ofVersion        = "openflow"
  global.sshTimeOut       = 5
  global.ofResetTimeOut   = 1
  global.ofSetupTime      = 2
  
  --- LaTeX
  global.tex = "pdflatex"
  
  --- logger file
  global.logFile = "sdn-cert.log"
  
  --- path settings
  global.results = "results"
  global.archive = "archive"
  global.scripts = "scripts"
  
  --- Keywords are stored lower-case and without underscore
  
  --- settings.cfg keywords:
  global.loadgenHost = "loadgenhost"
  global.loadgenWd   = "loadgenwd"
  global.switchIP    = "switchip"
  global.switchPort  = "switchport"
  global.phyLinks    = "links"
  
  --- benchmark keywords
  global.include         = {"include", "import"}
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
  
  --- special characters
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
        debug = false
        
        # Make archive before delting everything
        archive = false
        
        # Automatically run LaTex to create PDFs
        runTex = true
        
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
