--Feature config file

FeatureConfig = {}

FeatureConfig.logicalOps = {
  all  = function(cond1, cond2) return not (cond1 == nil and cond2 == nil) and (cond1 == nil or cond1) and (cond2 == nil or cond2) end,
  any  = function(cond1, cond2) return cond1 or (cond2 ~= nil and cond2) end,
  one  = function(cond1, cond2) return ((cond1 or cond2) and not (cond1 and cond2)) or false end,
}

FeatureConfig.enum = {
  ETH_TYPE  = { ip4 = 0x0800, ip6 = 0x86dd, arp = 0x0806, wol = 0x0842 },
  PROTO     = { udp = 0x11, tcp = 0x06, icmp = 0x01, undef = nil },
  TOS       = { dft = 0x00, mod = 0x80},
  TTL       = { max = 64, min = 1},
}

FeatureConfig.orgPkt = {
  ETH_TYPE4 = FeatureConfig.enum.ETH_TYPE.ip4,
  ETH_TYPE6 = FeatureConfig.enum.ETH_TYPE.ip6,
  SRC_MAC   = "aa:00:00:00:00:a1",
  DST_MAC   = "ff:ff:ff:ff:ff:ff", 
  SRC_IP4   = "10.0.1.1",
  SRC_IP6   = "fc00:0000:0000:0000:0000:0000:0001:0001",
  DST_IP4   = "10.0.1.2",
  DST_IP6   = "fc00:0000:0000:0000:0000:0000:0001:0002",
  PROTO     = FeatureConfig.enum.PROTO.udp,
  SRC_PORT  = 1234, 
  DST_PORT  = 5678,
  TOS       = FeatureConfig.enum.TOS.dft,
  TTL       = FeatureConfig.enum.TTL.max,
}

FeatureConfig.modPkt = {
  ETH_TYPE  = FeatureConfig.enum.ETH_TYPE.wol,
  SRC_MAC   = "aa:00:00:00:00:a2",
  DST_MAC   = "aa:aa:aa:aa:aa:aa", 
  SRC_IP4   = "10.0.2.1",
  SRC_IP6   = "fc00:0000:0000:0000:0000:0000:0002:0001",
  DST_IP4   = "10.0.2.2",
  DST_IP6   = "fc00:0000:0000:0000:0000:0000:0002:0001",
  PROTO     = FeatureConfig.enum.PROTO.tcp,
  SRC_PORT  = 4321, 
  DST_PORT  = 8765,
  TOS       = FeatureConfig.enum.TOS.mod,
  TTL       = FeatureConfig.enum.TTL.min,
}

-- is filled and modified during runtime
FeatureConfig.pkt = {}

function FeatureConfig.createPkt()
  for k,v in pairs(FeatureConfig.orgPkt) do
    FeatureConfig.pkt[k] = v
  end
end

FeatureConfig.feature = {
  default = {
    -- default flow rule if nothing else matches
    flowEntries = function(flows, ...)
        table.insert(flows, "priority=0, actions=DROP")
        end,
    -- implicit counter check if nothing is specified
    evalCounter = function (ctrs) return ctrs[1] > 0 end,
  },

  match_inport = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        if (not ...) then return end
        for i,v in ipairs({...}) do
          table.insert(flows, "in_port=" .. v .. ", actions=ALL")
        end end,
    modifyPkt = nil,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }
  },
  
  match_ethertype = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "dl_type=" .. FeatureConfig.orgPkt.ETH_TYPE4 .. ", actions=ALL")
        table.insert(flows, "dl_type=" .. FeatureConfig.orgPkt.ETH_TYPE6 .. ", actions=ALL")
        table.insert(flows, "dl_type=" .. FeatureConfig.modPkt.ETH_TYPE .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.ETH_TYPE = FeatureConfig.modPkt.ETH_TYPE
        FeatureConfig.pkt.PROTO = FeatureConfig.enum.PROTO.undef
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }
  },
  
  match_l2addr = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "dl_src=" .. FeatureConfig.orgPkt.SRC_MAC .. ", dl_dst=" .. FeatureConfig.orgPkt.DST_MAC .. ", actions=ALL")
        table.insert(flows, "dl_src=" .. FeatureConfig.modPkt.SRC_MAC .. ", dl_dst=" .. FeatureConfig.modPkt.DST_MAC .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.SRC_MAC = FeatureConfig.modPkt.SRC_MAC
        FeatureConfig.pkt.DST_MAC = FeatureConfig.modPkt.DST_MAC
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },  
  
  match_tos = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, nw_tos=" .. FeatureConfig.orgPkt.TOS .. ", actions=ALL")
        table.insert(flows, "ip, nw_tos=" .. FeatureConfig.modPkt.TOS .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.TOS = FeatureConfig.modPkt.TOS
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
    
  match_ttl = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, nw_ttl=" .. FeatureConfig.orgPkt.TTL .. ", actions=ALL")
        table.insert(flows, "ip, nw_ttl=" .. FeatureConfig.modPkt.TTL .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.TTL = FeatureConfig.modPkt.TTL
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
    
  match_ipv4 = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, nw_src=" .. FeatureConfig.orgPkt.SRC_IP4 .. ", nw_dst=" .. FeatureConfig.orgPkt.DST_IP4 .. ", actions=ALL")
        table.insert(flows, "ip, nw_src=" .. FeatureConfig.modPkt.SRC_IP4 .. ", nw_dst=" .. FeatureConfig.modPkt.DST_IP4 .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.SRC_IP4 = FeatureConfig.modPkt.SRC_IP4
        FeatureConfig.pkt.DST_IP4 = FeatureConfig.modPkt.DST_IP4
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
    
  match_ipv6 = {
    settings = {
      ip6     = true,
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ipv6, ipv6_src=" .. FeatureConfig.orgPkt.SRC_IP6 .. ", ipv6_dst=" .. FeatureConfig.orgPkt.DST_IP6 .. ", actions=ALL")
        table.insert(flows, "ipv6, ipv6_src=" .. FeatureConfig.modPkt.SRC_IP6 .. ", ipv6_dst=" .. FeatureConfig.modPkt.DST_IP6 .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.SRC_IP6 = FeatureConfig.modPkt.SRC_IP6
        FeatureConfig.pkt.DST_IP6 = FeatureConfig.modPkt.DST_IP6
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
  
  match_l3proto = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, nw_proto=" .. FeatureConfig.orgPkt.PROTO .. ", actions=ALL")
        table.insert(flows, "ip, nw_proto=" .. FeatureConfig.modPkt.PROTO .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.PROTO = FeatureConfig.modPkt.PROTO
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
    
  match_l4port = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, udp, tp_src=" .. FeatureConfig.orgPkt.SRC_PORT .. ", tp_dst=" .. FeatureConfig.orgPkt.DST_PORT .. ", actions=ALL")
        table.insert(flows, "ip, udp, tp_src=" .. FeatureConfig.modPkt.SRC_PORT .. ", tp_dst=" .. FeatureConfig.modPkt.DST_PORT .. ", actions=DROP")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.SRC_PORT = FeatureConfig.modPkt.SRC_PORT
        FeatureConfig.pkt.DST_PORT = FeatureConfig.modPkt.DST_PORT
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
    }      
  },
 
  modify_l2addr = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "actions=mod_dl_src=" .. FeatureConfig.modPkt.SRC_MAC .. ", mod_dl_dst=" .. FeatureConfig.modPkt.DST_MAC .. ", ALL")
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
      pktClassifier  = function(pkt) return (pkt.src_mac == FeatureConfig.modPkt.SRC_MAC and pkt.dst_mac == FeatureConfig.modPkt.DST_MAC) end,
    }      
  },
  
  modify_tos = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, actions=mod_nw_tos=" .. FeatureConfig.modPkt.TOS .. ", ALL")
        table.insert(flows, "ipv6, actions=mod_nw_tos=" .. FeatureConfig.modPkt.TOS .. ", ALL")
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
      pktClassifier  = function(pkt) return (pkt.tos == FeatureConfig.modPkt.TOS) end,
    }      
  },
  
  modify_ttl = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, actions=dec_ttl, ALL")
        table.insert(flows, "ipv6, actions=dec_ttl, ALL")
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
      pktClassifier  = function(pkt) return (pkt.ttl == FeatureConfig.orgPkt.TTL - 1) end,
    }      
  },
  
  modify_ipv4 = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, actions=mod_nw_src=" .. FeatureConfig.modPkt.SRC_IP4 .. ",mod_nw_dst=" .. FeatureConfig.modPkt.DST_IP4 .. ", ALL")
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
      pktClassifier  = function() return (pkt.src_ip == FeatureConfig.modPkt.SRC_IP4 and pkt.dst_ip == FeatureConfig.modPkt.DST_IP4) end,
    }      
  },

  -- OpenFlow does not directly support modifying IPv6 addresses, but (>OF1.2) can manually modify arbitrary fields
  modify_ipv6 = {
    settings = {
      ip6     = true,
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ipv6, actions=set_field:" .. FeatureConfig.modPkt.SRC_IP6 .. "->ipv6_src, set_field:" .. FeatureConfig.modPkt.DST_IP6 .. "->ipv6_dst, ALL")
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 1,
      pktClassifier  = function() return (pkt.src_ip == FeatureConfig.modPkt.SRC_IP6 and pkt.dst_ip == FeatureConfig.modPkt.DST_IP6) end,
    }      
  },
  
  modify_l4port = {
    settings = {
      timeout = 2,
    },
    flowEntries = function(flows, ...)
        table.insert(flows, "ip, udp, actions=mod_tp_src=" .. FeatureConfig.modPkt.SRC_PORT .. ", mod_tp_dst=" .. FeatureConfig.modPkt.DST_PORT .. ", ALL")
        table.insert(flows, "ip, tcp, actions=mod_tp_src=" .. FeatureConfig.modPkt.SRC_PORT .. ", mod_tp_dst=" .. FeatureConfig.modPkt.DST_PORT .. ", ALL")
        end,
    modifyPkt = function()
        FeatureConfig.pkt.PROTO = FeatureConfig.enum.PROTO.tcp
        end,
    evalCrit = {
      ctrType        = "any",
      desiredCtr     = 2,
      pktClassifier  = function(pkt) return (pkt.src_port == FeatureConfig.modPkt.SRC_PORT and pkt.dst_port == FeatureConfig.modPkt.DST_PORT) end,
    }      
  },
}


FeatureConfig.evalCrit = {
  modify_l2addr = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.src_mac == MOD_MAC or pkt.dst_mac == MOD_MAC) end,
  },
  modify_tos = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.tos == MOD_TOS) end,
  },
  modify_ttl = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.ttl == TTL - 1) end,
  },
  modify_ipv4 = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) end,
  },
  modify_ipv6 = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv6 or pkt.dst_ip == MOD_IP.ipv6) end,
  },
  modify_l4port = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.src_port == MOD_PORT or pkt.dst_port == MOD_PORT) end, 
  },
  action_normal = {
    ctrType        = "all",
    desiredCtr     = 1,
  },
  action_flood = {
    ctrType        = "all",
    desiredCtr     = 1,
  },
  action_duplicate = {
    ctrType        = "any",
    desiredCtr     = 2,
  },
  action_setfield = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.ttl == 1) end,
 
  },
  action_group_all = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) if (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip ~= MOD_IP.ipv4) then return 1
                                     elseif (pkt.src_ip ~= MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) then return 2
                                     else return 0 end end,
    evalCounter   = function (ctrs, threshold) return (ctrs[1] > threshold or ctrs[2] > threshold) end, 
  },
  action_group_indirect = { 
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) return (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) end,
  },
  action_group_select = {
    ctrType        = "any",
    desiredCtr     = 1,
    pktClassifier  = function (pkt) if (pkt.src_ip == MOD_IP.ipv4 and pkt.dst_ip ~= MOD_IP.ipv4) then return 1
                                     elseif (pkt.src_ip ~= MOD_IP.ipv4 and pkt.dst_ip == MOD_IP.ipv4) then return 2
                                     else return 0 end end,
    evalCounter   = function (ctrs, threshold) return (ctrs[1] > threshold or ctrs[2] > threshold) end,
  },
}

return FeatureConfig