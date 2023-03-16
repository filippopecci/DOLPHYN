function ng_investment_charge!(EP::Model, inputs::Dict, setup::Dict)

	println("Natural Gas Storage Charge Investment Module")

	dfRes = inputs["dfNGRes"]

	STOR_ASYMMETRIC = inputs["ng_STOR_ASYMMETRIC"] # Set of storage resources with asymmetric (separte) charge/discharge capacity components

	NEW_CAP_CHARGE = inputs["ng_NEW_CAP_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for new charge capacity
	RET_CAP_CHARGE = inputs["ng_RET_CAP_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements

	### Variables ###

	## Storage capacity built and retired for storage resources with independent charge and discharge power capacities (STOR=2)

	# New installed charge capacity of resource "y"
	@variable(EP, vNGCAPCHARGE[y in NEW_CAP_CHARGE] >= 0)

	# Retired charge capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPCHARGE[y in RET_CAP_CHARGE] >= 0)

	### Expressions ###
	@expression(EP, eNgExistingCapCharge[y in STOR_ASYMMETRIC], dfRes[y,:Existing_Cap_Charge_MMBTU_day])
	

	@expression(EP, eNgTotalCapCharge[y in STOR_ASYMMETRIC],
		if (y in intersect(NEW_CAP_CHARGE, RET_CAP_CHARGE))
			eNgExistingCapCharge[y] + vNGCAPCHARGE[y] - vNGRETCAPCHARGE[y]
		elseif (y in setdiff(NEW_CAP_CHARGE, RET_CAP_CHARGE))
			eNgExistingCapCharge[y] + vNGCAPCHARGE[y]
		elseif (y in setdiff(RET_CAP_CHARGE, NEW_CAP_CHARGE))
			eNgExistingCapCharge[y] - vNGRETCAPCHARGE[y]
		else
			eNgExistingCapCharge[y] + EP[:vZERO]
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new charge capacity, fixed costs are only O&M costs
	@expression(EP, eNgCFixCharge[y in STOR_ASYMMETRIC],
		if y in NEW_CAP_CHARGE # Resources eligible for new charge capacity
			dfRes[y,:InvCost_Charge_per_MMBTU_day]*vNGCAPCHARGE[y] + dfRes[y,:Fixed_OM_Cost_Charge_per_MMBTU_day]*eNgTotalCapCharge[y]
		else
			dfRes[y,:Fixed_OM_Cost_Charge_per_MMBTU_day]*eNgTotalCapCharge[y]
		end
	)

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eNgTotalCFixCharge, sum(EP[:eNgCFixCharge][y] for y in STOR_ASYMMETRIC))

	# Add term to objective function expression

	EP[:eObj] += eNgTotalCFixCharge
	

	### Constratints ###

	## Constraints on retirements and capacity additions
	#Cannot retire more charge capacity than existing charge capacity
	@constraint(EP, cNgMaxRetCharge[y in RET_CAP_CHARGE], vNGRETCAPCHARGE[y] <= eNgExistingCapCharge[y])

  	#Constraints on new built capacity

	# Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
    @constraint(EP, cNgMaxCapCharge[y in intersect(dfRes[dfRes.Max_Cap_Charge_MMBTU_day.>0,:R_ID], STOR_ASYMMETRIC)], eNgTotalCapCharge[y] <= dfRes[y,:Max_Charge_Cap_MMBTU_day])

	# Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
    @constraint(EP, cNMinCapCharge[y in intersect(dfRes[dfRes.Min_Cap_Charge_MMBTU_day.>0,:R_ID], STOR_ASYMMETRIC)], eNgTotalCapCharge[y] >= dfRes[y,:Min_Charge_Cap_MMBTU_day])


end
