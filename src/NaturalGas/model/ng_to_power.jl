function ng_to_power!(EP,inputs,setup)
    
    print_and_log("Natural Gas to Power Module")

    Pgen = inputs["ng_P_GEN"];

    β = Int(inputs["hours_per_subperiod"]/inputs["ng_days_per_subperiod"]);

    ngT = inputs["ng_T"];

    Z = inputs["Z"];

    dfGen = inputs["dfGen"];
 
    @variable(EP, vNGP[y in Pgen, t in 1:ngT] >=0)

    # Natural Gas that is used by power generators
    @expression(EP, eNgBalancePower[t=1:ngT, z=1:Z], sum(vNGP[y,t] for y in intersect(Pgen, dfGen[dfGen[!,:Zone].==z,:R_ID])))
        
    # Natural Gas Balance Expression
    EP[:eNgBalance] += - eNgBalancePower;

    # When ParameterScale= 1 power variables are defined in GW rather than MW.
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    # Natural gas used during a given day is equal to total energy generated during that day times the heat rate
    @constraint(EP,cNgGas2Power[y in Pgen,t in 1:ngT], vNGP[y,t] ==  (dfGen[y,:Heat_Rate_MMBTU_per_MWh]*scale_factor)*sum(EP[:vP][y,s] for s in (t-1)*β + 1 : t*β))

 
end