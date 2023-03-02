function ng_to_hydrogen!(EP,inputs,setup)
    
    print_and_log("Natural Gas to H2 Module")

    H2gen = inputs["ng_H2_GEN"];

    β = Int(inputs["hours_per_subperiod"]/inputs["ng_days_per_subperiod"]);

    ngT = inputs["ng_T"];

    Z = inputs["Z"];

    dfH2Gen = inputs["dfH2Gen"];
 
    @variable(EP, vNGH2[y in H2gen, t in 1:ngT] >=0)

    # Natural Gas that is used by H2 generators
    @expression(EP, eNgBalanceH2[t=1:ngT, z=1:Z], sum(vNGH2[y,t] for y in intersect(H2gen, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])))
        
    # Natural Gas Balance Expression
    EP[:eNgBalance] += - eNgBalanceH2;

    # Natural gas used during a given day is equal to total hydrogen generated during that day times the fuel to hydrogen rate
    @constraint(EP,cNgGas2Hydrogen[y in H2gen,t in 1:ngT], vNGH2[y,t] == dfH2Gen[y,:etaFuel_MMBtu_p_tonne]*sum(EP[:vH2Gen][y,s] for s in (t-1)*β + 1 : t*β))

 
end