function ng_emissions!(EP::Model, inputs::Dict,setup::Dict)

	println("Natural Gas Emissions Module (for CO2 Policy modularization)")

	T = inputs["ng_T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    @expression(EP, eNgEmissionsByZone[z=1:Z, t=1:T], inputs["ng_CO2_per_MMBTU"]*(inputs["ng_D"][t,z] - sum(EP[:eNgCNS][s,t,z] for s in 1:inputs["ng_SEG"])));

end
