function ng_discharge!(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Natural Gas Discharge Module")

    T = inputs["ng_T"];     # Number of time steps (days)
	Z = inputs["Z"];     # Number of zones - assumed to be same for power, hydrogen, and natural gas system
    SOURCE = inputs["ng_SOURCE"];#Index set of natural gas sources
    R = inputs["ng_R"]; # Number of natural gas resources
    dfRes = inputs["dfNGRes"];

    # Natural gas that is injected by resource "y" at day "t"
    @variable(EP,vNG[y=1:R,t=1:T]>=0)

    # Natural Gas that is injected in the network by different resources
    @expression(EP, eNgBalanceInj[t=1:T, z=1:Z], sum(vNG[y,t] for y in intersect(1:R, dfRes[dfRes[!,:Zone].==z,:R_ID])));
    
    EP[:eNgBalance] += eNgBalanceInj;

end