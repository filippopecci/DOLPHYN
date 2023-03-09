function ng_discharge!(EP,inputs,setup)

    ngT = inputs["ng_T"];     # Number of time steps (days)
	Z = inputs["Z"];     # Number of zones - assumed to be same for power, hydrogen, and natural gas system
    SOURCE = inputs["ng_SOURCE"];#Index set of natural gas sources
    ngR = inputs["ng_R"]; # Number of natural gas resources
    df = inputs["dfNGRes"];
    # Natural gas that is injected by resource "y" at day "t"
    @variable(EP,vNG[y=1:ngR,t=1:ngT]>=0)

    # Natural Gas that is injected in the network by different resources
    @expression(EP, eNgBalanceInj[t=1:ngT, z=1:Z], sum(vNG[y,t] for y in intersect(1:ngR, df[df[!,:Zone].==z,:R_ID])));

    EP[:eNgBalance] += eNgBalanceInj;

    # Cost of natural gas injection from source "y" at day "t"
    @expression(EP,eNgCVar_source_inj[y in SOURCE,t=1:ngT],inputs["ng_fuel_costs"][df[y,:Fuel]][t]*vNG[y,t])

    @expression(EP,eNgTotalCVarSourceInjT[t=1:ngT],sum(eNgCVar_source_inj[y,t] for y in SOURCE))

    @expression(EP,eNgTotalCVarSourceInj,sum(eNgTotalCVarSourceInjT[t] for t in 1:ngT))

    EP[:eObj] += eNgTotalCVarSourceInj;

    # Discharge capacity constraint
    @constraint(EP,cNgInj[y in 1:ngR,t in 1:ngT],vNG[y,t]<=EP[:eNgTotalCap][y]);


end