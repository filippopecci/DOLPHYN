function co2_cap_ng!(EP::Model, inputs::Dict, setup::Dict)

	println("Natural Gas C02 Policies Module")

	dfRes = inputs["dfNGRes"]
	SEG = inputs["SEG"]  # Number of lines
	R = inputs["ng_R"]     # Number of resources
	T = inputs["T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones

	### Constraints ###

	## Mass-based: Emissions constraint in absolute emissions limit (tons)
	if setup["NGCO2Cap"] == 1
		@constraint(EP, cNgCO2Emissions_systemwide[cap=1:inputs["ng_NCO2Cap"]],
			sum(EP[:eNgEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfNgCO2CapZones"][:,cap]), t=1:T) <=
			sum(inputs["dfNgMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfNgCO2CapZones"][:,cap])))

	## Load + Rate-based: Emissions constraint in terms of rate (tons/MMBTU)
	elseif setup["CO2Cap"] == 2 
        error("No Load Rate CO2 Emission Cap for Natural Gas!")
	## Generation + Rate-based: Emissions constraint in terms of rate 
	elseif (setup["CO2Cap"]==3)
        error("No Generation Rate CO2 Emission Cap for Natural Gas!")
	end 

end
