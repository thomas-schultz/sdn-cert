# sdn-cert
OpenFlow Switch certification tool (work in progress)


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
	
# Benchmarks
	Testcases are defined in multiple layers:
	Layer 1:
		benchmark.cfg: List of testcases with name and variables in form of key=value
	Layer 2:
		stored in benchmark-files/config/<name>.lua
		See benchmark-files/benchmark_template.lua for details

		All Arguments beginning with '$' are treated as variables. All variables from the
		upper layer is passed downwards. So it is possible to define or override variables
		from layer 1 here.
		
		SPECIAL:
			files are currently identified by $file=#, where # stands for the index of the
			file in the list above. Physical connections between the switch and the loadgen
			are addressed by index. Use $link=1 to use the first connection. $link=* will
			match to a list of all available connections
			
		HINT: all keys are stored in lower case and without underscores. So 'rx_port' will
			refer to the same value as "rxPort". Values are not changed in any way.
	layer 3:
		moongen scripts: invidual scripts for generating and evaluating the result
			
# Feature-Test
	uses nearly the same structure as benchmarks, but without Layer 1
	Layer 2:
		stored in feature-tests/config/<name>.lua
		See feature-tests/feature_template.lua for details
		
		A simple feature test will work like this:
			1)	install rules
			2)	generate specific packet
			3)	modify packet and jump to 2) or continue
			4)	receive all packets, storing them in a table
			5)	check if number of packets is as expected
			6)	check if packet content is as expected
			7)	report result
		
	Layer 3:
		moongen script: one script, that performs the generating and checks the result with
		the given configuration.