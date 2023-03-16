function ng_demand_curtailment!(EP,inputs,setup)

    print_and_log("Natural Gas Demand Curtailment Module")

    ngT = inputs["ng_T"]     # Number of time steps (days)
    ngSEG = inputs["ng_SEG"] # Number of load curtailment segments
	Z = inputs["Z"]     # Number of zones

    @variable(EP,vNGNS[s in 1:ngSEG, t in 1:ngT, z in 1:Z]>=0)

    # Cost of non-served natural gas/curtailed demand at day "t" in zone "z"
	@expression(EP, eNgCNS[s=1:ngSEG,t=1:ngT,z=1:Z], (inputs["pC_D_Curtail"][s]*vNGNS[s,t,z]))

	# Sum individual demand segment contributions to non-served natural gas costs to get total non-served natural gas costs
	@expression(EP, eNgTotalCNSTS[t=1:ngT,z=1:Z], sum(eNgCNS[s,t,z] for s in 1:ngSEG))
	@expression(EP, eNgTotalCNST[t=1:ngT], sum(eNgTotalCNSTS[t,z] for z in 1:Z))
	@expression(EP, eNgTotalCNS, sum(eNgTotalCNST[t] for t in 1:ngT))
    EP[:eObj] += eNgTotalCNS;

    ## Natural Gas Balance Expression ##
    @expression(EP, eNgBalanceNS[t=1:ngT, z=1:Z],sum(vNGNS[s,t,z] for s=1:ngSEG))

	# Add non-served natural gas/curtailed demand contribution to natural gas balance expression
	EP[:eNgBalance] += eNgBalanceNS;

    # Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(EP,cNgMaxDemCurtail[s in 1:ngSEG, t in 1:ngT,z in 1:Z], vNGNS[s,t,z]<= inputs["ng_Max_D_Curtail"][s]*inputs["ng_D"][t,z]);
    
    # Total demand curtailed in each time step (daily) cannot exceed total demand
	@constraint(EP, cNgMaxNS[t=1:ngT, z=1:Z], sum(vNGNS[s,t,z] for s=1:ngSEG) <= inputs["ng_D"][t,z])

    

end