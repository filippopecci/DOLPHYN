function ng_storage!(EP,inputs,setup)

    print_and_log("Natural Gas Storage Module")

    df = inputs["dfNGRes"];

	ngT = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones

    STOR = inputs["ng_STOR"]; # Index set of storage resources

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

    STOR_LNG_TERM = union(STOR,LNG_TERM);

    @variable(EP,vNGSTOR[y in STOR_LNG_TERM, t in 1:ngT]>=0)
    
    @variable(EP,vNGCHARGE[y in STOR_LNG_TERM,t in 1:ngT] >=0)
    
    # Natural Gas that is extracted by storage resources that are supplied by the network
    @expression(EP, eNgBalanceStorCharge[t=1:ngT,z=1:Z], sum(vNGCHARGE[y,t] for y in intersect(STOR, df[df[!,:Zone].==z,:R_ID])))
        
    # Natural Gas Balance Expression
    EP[:eNgBalance] += - eNgBalanceStorCharge ;
    
    # Storage capacity constraint (state of charge)
    @constraint(EP, cNgStorLevel[y in STOR_LNG_TERM,t in 1:ngT], vNGSTOR[y,t] <= EP[:eNgTotalCapStor][y]);

    # Minimum storage level 
    @constraint(EP,cNgStorMin[y in STOR_LNG_TERM, t in 1:ngT], vNGSTOR[y,t] >= df[y,:Min_Stor_Level]*EP[:eNgTotalCapStor][y]);

    # Charge capacity constraint for those that have bounded capacity
    @constraint(EP,cNgStorCharge[y in STOR, t in 1:ngT], vNGCHARGE[y,t] <= EP[:eNgTotalCapCharge][y])

    # Storage tank operation with circular indexing
	START_SUBPERIODS = inputs["ng_START_SUBPERIODS"]

	INTERIOR_SUBPERIODS = inputs["ng_INTERIOR_SUBPERIODS"]

	days_per_subperiod = inputs["ng_days_per_subperiod"] #total number of days per subperiod

    @constraint(EP, cNgSoCBalStart[y in STOR_LNG_TERM, t in START_SUBPERIODS], vNGSTOR[y,t] == vNGSTOR[y,t+days_per_subperiod-1]-(1/df[y,:Eff_Down]*EP[:vNG][y,t]) +(df[y,:Eff_Up]*vNGCHARGE[y,t])-(df[y,:Self_Disch]*vNGSTOR[y,t+days_per_subperiod-1]))

    @constraint(EP, cNGSoCBalInterior[y in STOR_LNG_TERM, t in INTERIOR_SUBPERIODS], vNGSTOR[y,t] == vNGSTOR[y,t-1]-(1/df[y,:Eff_Down]*EP[:vNG][y,t])+(df[y,:Eff_Up]*vNGCHARGE[y,t])-(df[y,:Self_Disch]*vNGSTOR[y,t-1]))

    # Cost of LNG imports by terminal "y" at day "t"
    @expression(EP,eNgCVar_lng_import[y in LNG_TERM,t=1:ngT],inputs["ng_fuel_costs"][df[y,:Fuel]][t]*vNGCHARGE[y,t])

    @expression(EP,eNgTotalCVarLngImportT[t=1:ngT],sum(eNgCVar_lng_import[y,t] for y in LNG_TERM))
    
    @expression(EP,eNgTotalCVarLngImport,sum(eNgTotalCVarLngImportT[t] for t in 1:ngT))
    
    EP[:eObj] += eNgTotalCVarLngImport;

end