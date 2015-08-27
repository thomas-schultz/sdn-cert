Global = {}
Global.__index = Global

global = {}

function Global.create ()
  -- main config
  global.config_file       = "settings.cfg"
  global.feature_list      = "feature_list.cfg"
  global.feature_file      = "features.cfg"
  global.benchmark_configs = "benchmark-configs"
  global.benchmark_files   = "benchmark-files"
  global.feature_tests     = "feature-tests"
  global.moongen_repo      = "https://github.com/emmericp/MoonGen"
  global.ofVersion         = "openflow"
  
  -- logger
  global.log_file = "sdn-cert.log"
  
  -- path settings
  global.results = "results"
  global.scripts = "scripts"
  
  --settings.cfg keywords:
  global.loadgen_host = "loadgenhost"
  global.loadgen_wd   = "loadgenwd"
  global.sdn_ip       = "sdnip"
  global.sdn_port     = "sdnport"
  global.connection   = "connections"
  global.of_con       = "ofcon"
  global.lg_con       = "lgcon"
  
  --benchmark keywords
  global.cfg_filetype    = ".cfg"
  global.requires        = "require"
  global.prepare         = "prepare"
  global.name            = "name"
  global.loop_count      = "loops"
  global.duration        = "duration"
  global.openflow_script = "ofscript"
  global.loadgen         = "loadgen"
  global.loadgen_arg     = "lgargs"
  global.copy_files      = "files"
  
  --special characters
  global.ch_var     = "%$"
  global.ch_comment = "#"
  global.ch_equal   = "="
  global.ch_connect = "-"
  
  
  global.default_cfg = [[
        # settings file
        
        # Debugging settings
        #debug = true
        
        OpenFlowVersion = OpenFlow10
        
        # set to true if this host is the load-generator
        local = true
        # ip,name or ssh alias of load-generator host, ignored if local is true
        load_gen_host = 127.0.0.1
        # working directory on load-gen
        load_gen_wd = /root
        
        # sdn-device configuration
        sdn_ip = 127.0.0.1
        sdn_port = 6633
        
        # moongen rx and tx port
        rx_port = 0
        tx_port = 1
  ]]
end
