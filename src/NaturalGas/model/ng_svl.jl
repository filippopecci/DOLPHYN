function ng_svl!(EP,inputs,setup)

    print_and_log("Natural Gas SVL Module")

    df = inputs["dfNGRes"];

	ngT = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones

    STOR = inputs["ng_STOR"]; # Index set of storage resources
    WDW = inputs["ng_WDW"]; # Index set of withdrawing resources
    LNG_IMP = inputs["ng_LNG_IMP"]; # Index set of LNG terminals (subset of STOR)

    @variable(EP,vNGWDW[y in WDW,t in 1:ngT]>=0)

    @variable(EP,vNGFILL[y in STOR, t in 1:ngT]>=0)

    @variable(EP,vNGSTORIN[y in STOR, t in 1:ngT]>=0)
        
    # Natural Gas that is extracted by resources with withdrawing capabilities
    @expression(EP, eNgBalanceStorWdw[t=1:ngT,z=1:Z], sum(vNGWDW[y,t] for y in intersect(WDW, df[df[!,:Zone].==z,:R_ID])))

    # Natural Gas that is injected by storage and vaporization resources
    @expression(EP, eNgBalanceStorInj[t=1:ngT, z=1:Z], sum(EP[:vNG][y,t] for y in intersect(STOR, df[df[!,:Zone].==z,:R_ID])))
        
    # Natural Gas Balance Expression
    EP[:eNgBalance] += eNgBalanceStorInj - eNgBalanceStorWdw ;
    
    # Storage capacity constraint (state of charge)
    @constraint(EP, cNgStorFill[y in STOR,t in 1:ngT], vNGFILL[y,t] <= EP[:eNgTotalCapStor][y]);

    # Minimum storage level 
    @constraint(EP,cNgStorMin[y in STOR, t in 1:ngT], vNGFILL[y,t] >= df[y,:StorMinLevel]*EP[:eNgTotalCapStor][y]);

    # Vaporization capacity constraint (storage discharge)
    @constraint(EP,cNgStorInj[y in STOR,t in 1:ngT],EP[:vNG][y,t]<=EP[:eNgTotalCapStorInj][y]);

    # Withdrawing capacity constraint (storage charge)
    @constraint(EP,cNgStorWdw[y in WDW, t in 1:ngT],vNGWDW[y,t]<=EP[:eNgTotalCapStorWdw][y])

    # Moving LNG into storage tanks. 
    # N.B. LNG Import Terminals are charged from out-of-model locations and variables "vNGSTORIN" are considered as free (there is a cost to be paid - see below)
    @constraint(EP,cNgMoveLNG[y in WDW, t in 1:ngT], sum(vNGSTORIN[w,t]  for w in df[df[!,:StorWdwFacility].==y,:R_ID]) == vNGWDW[y,t])

    # Storage tank operation with circular indexing
	START_SUBPERIODS = inputs["ng_START_SUBPERIODS"]

	INTERIOR_SUBPERIODS = inputs["ng_INTERIOR_SUBPERIODS"]

	days_per_subperiod = inputs["ng_days_per_subperiod"] #total number of days per subperiod

    @constraint(EP, cNgSoCBalStart[y in STOR, t in START_SUBPERIODS], vNGFILL[y,t] == vNGFILL[y,t+days_per_subperiod-1]-(1/df[y,:InjEff_Down]*EP[:vNG][y,t]) +(df[y,:WdwEff_Up]*vNGSTORIN[y,t])-(df[y,:Stor_Self_Disch]*vNGFILL[y,t+days_per_subperiod-1]))

    @constraint(EP, cNGSoCBalInterior[y in STOR, t in INTERIOR_SUBPERIODS], vNGFILL[y,t] == vNGFILL[y,t-1]-(1/df[y,:InjEff_Down]*EP[:vNG][y,t])+(df[y,:WdwEff_Up]*vNGSTORIN[y,t])-(df[y,:Stor_Self_Disch]*vNGFILL[y,t-1]))

    # Cost of natural gas imports by resource "y" at day "t"
    @expression(EP,eNgCVar_lng_import[y in LNG_IMP,t=1:ngT],inputs["ng_fuel_costs"][df[y,:Fuel_Cost]][t]*vNGSTORIN[y,t])

    @expression(EP,eNgTotalCVarLngImportT[t=1:ngT],sum(eNgCVar_lng_import[y,t] for y in LNG_IMP))
    
    @expression(EP,eNgTotalCVarLngImport,sum(eNgTotalCVarLngImportT[t] for t in 1:ngT))
    
    EP[:eObj] += eNgTotalCVarLngImport;

end