#!/bin/bash

if [ $# -lt 3 ]; then
	echo "Usage: script <ip> <port> <feature> [args]"
	exit
fi
IP=$1
PORT=$2
FEATURE=$3
shift; shift; shift

ovs-ofctl del-flows tcp:$IP:$PORT
ovs-ofctl del-meters tcp:$IP:$PORT -O OpenFlow13
ovs-ofctl del-groups tcp:$IP:$PORT -O OpenFlow11

case "$FEATURE" in
# == Matching ==
        match_inport)
        	for IN in "$@"
			do
   				ovs-ofctl add-flow tcp:$IP:$PORT "in_port=$IN, actions=ALL"
			done
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        match_ethertype)
        	# match ip packet
            ovs-ofctl add-flow tcp:$IP:$PORT "dl_type=0x0800, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
        
        match_tos)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_tos=0x00, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        match_ttl)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_ttl=64, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
         
        match_l2addr)
            ovs-ofctl add-flow tcp:$IP:$PORT "dl_src=aa:bb:cc:dd:ee:ff dl_dst=ff:ff:ff:ff:ff:ff, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        match_ipv4)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_src=10.0.0.1, nw_dst=10.0.0.2, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
         
        match_ipv6)
            ovs-ofctl add-flow tcp:$IP:$PORT "ipv6, ipv6_src=fc00::1, ipv6_dst=fc00::2, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
         
        match_l3proto)
        	# match UDP packets
	    	ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_proto=17, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
         
        match_l4port)
        	# match UDP packets
	    	ovs-ofctl add-flow tcp:$IP:$PORT "ip, udp, tp_src=1234, tp_dst=4321, actions=ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
# == Modifying ==
        modify_tos)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_tos=0x00, actions=mod_nw_tos=0x10, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
  
		modify_ttl)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_ttl=64, actions=dec_ttl, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
                      
        modify_l2addr)
        	# match ip packet
            ovs-ofctl add-flow tcp:$IP:$PORT "dl_src=aa:bb:cc:dd:ee:ff dl_dst=ff:ff:ff:ff:ff:ff, actions=mod_dl_src=ff:ee:dd:cc:bb:aa, mod_dl_dst=ff:ee:dd:cc:bb:aa, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
         
        modify_ipv4)
            ovs-ofctl add-flow tcp:$IP:$PORT "ip, nw_src=10.0.0.1, nw_dst=10.0.0.2, actions=mod_nw_src=10.0.0.3, mod_nw_dst=10.0.0.3, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        modify_ipv6)
	    	# Openflow dows not directly support modifying IPv6 addresses, but it can manually modify arbitrary fields
	    	ovs-ofctl add-flow tcp:$IP:$PORT "ipv6, ipv6_src=fc00::1, ipv6_dst=fc00::2, actions=set_field:fc00::3->ipv6_src, set_field:fc00::3->ipv6_dst, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        modify_l4port)
	    	ovs-ofctl add-flow tcp:$IP:$PORT "ip, udp, tp_src=1234, tp_dst=4321, actions=mod_tp_src=5555, mod_tp_dst=5555, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
# == Modifying ==
 		action_normal)
	    	ovs-ofctl add-flow tcp:$IP:$PORT "actions=NORMAL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
 		action_flood)
	    	ovs-ofctl add-flow tcp:$IP:$PORT "actions=FLOOD"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
 		action_duplicate)
	    	ovs-ofctl add-flow tcp:$IP:$PORT "actions=output:$1,$2,$2"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        action_setfield)
	    	ovs-ofctl add-flow tcp:$IP:$PORT "ip, actions=set_field:1->nw_ttl, ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;

        action_group_all)
	    	ovs-ofctl add-group tcp:$IP:$PORT -O Openflow11 "group_id=1, type=all, bucket=mod_nw_src=10.0.0.3,ALL, bucket=mod_nw_dst=10.0.0.3,ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT -O Openflow11 "ip, actions=group:1"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;
            
        action_group_indirect)
	    	ovs-ofctl add-group tcp:$IP:$PORT -O Openflow11 "group_id=1, type=indirect, bucket=mod_nw_src=10.0.0.3,mod_nw_dst=10.0.0.3,ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT -O Openflow11 "ip, actions=group:1"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;; 
            
        action_group_select)
	    	ovs-ofctl add-group tcp:$IP:$PORT -O Openflow11 "group_id=1, type=select, bucket=mod_nw_src=10.0.0.3,ALL, bucket=mod_nw_dst=10.0.0.3,ALL"
	    	ovs-ofctl add-flow tcp:$IP:$PORT -O Openflow11 "ip, actions=group:1"
	    	ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            ;;          

        *)
            echo "Unknown feature test"
            ovs-ofctl add-flow tcp:$IP:$PORT "priority=0, actions=DROP"
            exit 1
 
esac