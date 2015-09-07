--Benchmark config file

BenchmarkConfig = {}

BenchmarkConfig.simple_throughput = function(flowData, inPort, outPort)
  table.insert(flowData.flows, "in_port=" .. inPort .. ", actions=output:" .. outPort)
end

return BenchmarkConfig