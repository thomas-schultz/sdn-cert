# sdn-cert
OpenFlow Switch certification tool (early alpha)


# dependencies:
	lua
	openvwitch
	ssh keys for root@loadgen_host
	link moongen to ./build/MoonGen in moongen directory

# start:	
	make changes in settings.conf
	configure OpenFlow-Switch to listen on selected Port
	setup MoonGen: ./run.sh --setup
	*look at help: ./run.sh --help
	start benchmark ./run.sh <benchmark.cfg>
	(start with --verbose and/or look at sdn-cert.log)
	
# genral info
	Testcases are defined in multiple layers:
	Layer 1:
		benchmark.cfg: List of testcases with name and variables in form of key=value
	Layer 2:
		benchmark-files/config/<name>.lua
		TODO:
		require:	required features, seperated by colon
		of_script:	script with openflow rules followed by arguments, at least $ip and $port, args seperated by colon
		load_gen:	loadgen programm
		files:		files to copy to the loadgen host, seperated by colon
		lg_args:	arguments passed to loaggen programm, lg_args
		All Arguments beginning with '$' are treated as variables. All vvariables from the upper layer is passed downwards. So it is 	possible to define or override variables here.
		
		SPECIAL: files are currently idetified by $file#, where # stands for the index of the file in the list above.
		HINT: all key are stored lower case and without '_'. So 'rx_port' is the same key as "rxPort". Values are not changed.
	layer 3:
		moongen script:
			custom script that performs the packet generation.
		