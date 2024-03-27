function ng_pipelines!(EP,inputs,setup)

    print_and_log("Natural Gas Pipelines Module")
    
    K = inputs["ngPipes"]
    T = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power, hydrogen, and natural gas system
    LOSS_PIPES = inputs["ng_LOSS_PIPES"] # Pipes for which loss coefficients apply (are non-zero);

    ### Variables ###

    # Natural gas flow in each pipe and day (uni-directional pipes)
    @variable(EP, vNGFLOW[k=1:K,t=1:T]>=0)

	# Transmission losses on each transmission line "l" at hour "t"
	@variable(EP, vNGPIPELOSS[l in LOSS_PIPES,t=1:T] >= 0)

    ### Expressions ###

    # Existing natural gal pipeline capacity
    @expression(EP,eNgExistingCapPipe[k=1:K], inputs["ngPipeFlow_Max"][k])    

    # Losses from natural gas flows into or out of zone "z" in MMBTU/day
    @expression(EP, eNgLosses_By_Zone[z=1:Z,t=1:T], sum(abs(inputs["ngNet_Map"][k,z]) * vNGPIPELOSS[k,t] for k in LOSS_PIPES))

    # Net export of natural gas from each zone
    @expression(EP, eNgNetExportFlows[z=1:Z,t=1:T], sum(inputs["ngNet_Map"][k,z] * vNGFLOW[k,t] for k=1:K));

    # Natural Gas Balance Expressions
    @expression(EP, eNgBalanceNetExportFlows[t=1:T, z=1:Z], -eNgNetExportFlows[z,t]);

	@expression(EP, eNgBalanceLossesByZone[t=1:T, z=1:Z], -(1/2)*eNgLosses_By_Zone[z,t])

    EP[:eNgBalance] += eNgBalanceNetExportFlows;

    EP[:eNgBalance] += eNgBalanceLossesByZone;

    ### Constraints ###

    @constraint(EP,cNgMaxFlow[k=1:K,t=1:T],vNGFLOW[k,t] <= eNgExistingCapPipe[k])

    @constraint(EP,cNgPipeLoss[k in LOSS_PIPES, t=1:T], vNGPIPELOSS[k,t] == inputs["ngPercent_Loss"][k]*vNGFLOW[k,t])


end
