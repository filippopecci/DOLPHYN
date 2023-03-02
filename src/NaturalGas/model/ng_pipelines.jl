function ng_pipelines!(EP,inputs,setup)

    print_and_log("Natural Gas Pipelines Module")
    
    K = inputs["ngPipes"]
    ngT = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power, hydrogen, and natural gas system

    # Natural gas flow in each pipe and day (uni-directional pipes)
    @variable(EP, vNGFLOW[k=1:K,t=1:ngT]>=0)

    # Maximum natural gas flow in each pipe
    @constraint(EP,cNgMaxFlow[k=1:K,t=1:ngT],vNGFLOW[k,t] <= EP[:eNgAvail_Pipe_Cap][k])

    # Net export of natural gas from zone "z" at day "t" in MMBTU
    @expression(EP, eNgNet_Export_Flows[z=1:Z,t=1:ngT], sum(inputs["ngNet_Map"][k,z] * vNGFLOW[k,t] for k=1:K));

    @expression(EP, eNgBalanceNetExportFlows[t=1:ngT, z=1:Z], -eNgNet_Export_Flows[z,t]);

    EP[:eNgBalance] += eNgBalanceNetExportFlows;

end