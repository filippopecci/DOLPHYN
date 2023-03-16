function ng_storage_all!(EP::Model, inputs::Dict, setup::Dict)
	# Setup variables, constraints, and expressions common to all storage resources
	print_and_log("Natural Gas Storage Core Resources Module")

	dfRes = inputs["dfNGRes"]

	R = inputs["ng_R"]     # Number of resources 
	T = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones

	STOR_ALL = inputs["ng_STOR_ALL"]

	### Variables ###

	# Storage level of resource "y" at day "t" [MMBTU] on zone "z" - unbounded
	@variable(EP, vNGS[y in STOR_ALL, t=1:T] >= 0);

	# Natural Gas withdrawn from system by resource "y" at day "t" [MMBTU/day] on zone "z"
	@variable(EP, vNGCHARGE[y in STOR_ALL, t=1:T] >= 0);

	### Expressions ###

	# Natural Gas losses related to technologies (increase in effective demand)
	@expression(EP, eNgELOSS[y in STOR_ALL], sum(vNGCHARGE[y,t] for t in 1:T) - sum(EP[:vNG][y,t] for t in 1:T))

	## Natural Gas Balance Expressions ##

	# Term to represent net dispatch from storage in any period
	@expression(EP, eNgBalanceStor[t=1:T, z=1:Z],
		sum(EP[:vNG][y,t]-EP[:vNGCHARGE][y,t] for y in intersect(dfRes[dfRes.Zone.==z,:R_ID],STOR_ALL)))

	EP[:eNgBalance] += eNgBalanceStor

	### Constraints ###

	# Maximum NG stored must be less than capacity
	@constraint(EP,cNgStorageCapacity[y in STOR_ALL, t in 1:T], EP[:vNGS][y,t] <= EP[:eNgTotalCapStor][y])

	
	@constraint(EP,cNgSoCBalInterior[t in 2:T, y in STOR_ALL], EP[:vNGS][y,t] == EP[:vNGS][y,t-1]-(1/dfRes[y,:Eff_Down]*EP[:vNG][y,t])+(dfRes[y,:Eff_Up]*EP[:vNGCHARGE][y,t])-(dfRes[y,:Self_Disch]*EP[:vNGS][y,t-1]))
	
                
	@constraint(EP, cNgSoCBalStart[y in STOR_ALL], EP[:vNGS][y,1] == EP[:vNGS][y,T]-(1/dfRes[y,:Eff_Down]*EP[:vNG][y,1]) +(dfRes[y,:Eff_Up]*EP[:vNGCHARGE][y,1])-(dfRes[y,:Self_Disch]*EP[:vNGS][y,T]))


	# Storage discharge and charge 

	# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
	# this constraint is set in functions below for each storage type

	# Maximum discharging rate must be less discharge capacity OR available stored natural gas in the prior day, whichever is less
	@constraints(EP, begin
			[y in STOR_ALL, t in 1:T], EP[:vNG][y,t] <= EP[:eNgTotalCap][y]
			[y in STOR_ALL, t in 2:T], EP[:vNG][y,t] <= EP[:vNGS][y,t-1]*dfRes[y,:Eff_Down]
			[y in STOR_ALL, t=1], EP[:vNG][y,t] <= EP[:vNGS][y,T]*dfRes[y,:Eff_Down]
		end)
	
    # Minimum storage level 
    @constraint(EP,cNgStorMin[y in STOR_ALL, t in 1:T], EP[:vNGS][y,t] >= dfRes[y,:Min_Stor_Level]*EP[:eNgTotalCapStor][y]);

    #From co2 Policy module
	@expression(EP, eNgELOSSByZone[z=1:Z],sum(EP[:eNgELOSS][y] for y in intersect(STOR_ALL, dfRes[dfRes[!,:Zone].==z,:R_ID])))

end