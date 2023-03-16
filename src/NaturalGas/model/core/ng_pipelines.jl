function ng_pipelines!(EP,inputs,setup)

    print_and_log("Natural Gas Pipelines Module")
    
    K = inputs["ngPipes"]
    T = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power, hydrogen, and natural gas system

    # Natural gas flow in each pipe and day (uni-directional pipes)
    @variable(EP, vNGFLOW[k=1:K,t=1:T]>=0)

    # Maximum natural gas flow in each pipe
    @expression(EP,eNgExistingCapPipe[k=1:K], inputs["ngPipeFlow_Max"][k])    

    @constraint(EP,cNgMaxFlow[k=1:K,t=1:T],vNGFLOW[k,t] <= eNgExistingCapPipe[k])
 
    @expression(EP, eNgNetExportFlows[z=1:Z,t=1:T], sum(inputs["ngNet_Map"][k,z] * vNGFLOW[k,t] for k=1:K));

    @expression(EP, eNgBalanceNetExportFlows[t=1:T, z=1:Z], -eNgNetExportFlows[z,t]);

    EP[:eNgBalance] += eNgBalanceNetExportFlows;

  
end