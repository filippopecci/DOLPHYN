function ng_investment_discharge!(EP::Model, inputs::Dict, setup::Dict)

	print_and_log("Natural Gas Investment Discharge")


	dfRes = inputs["dfNGRes"];

	R = inputs["ng_R"] # Number of resources (LNG terminals, sources, storage)

	NEW_CAP = inputs["ng_NEW_CAP"] # Set of all resources eligible for new capacity
	RET_CAP = inputs["ng_RET_CAP"] # Set of all resources eligible for capacity retirements

	### Variables ###

	# Retired capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAP[y in RET_CAP] >= 0);

    # New installed capacity of resource "y"
	@variable(EP, vNGCAP[y in NEW_CAP] >= 0);

    ### Expressions ###

	@expression(EP, eNgExistingCap[y in 1:R], dfRes[y,:Existing_Cap_MMBTU_day])
	
	@expression(EP, eNgTotalCap[y in 1:R],
		if y in intersect(NEW_CAP, RET_CAP) # Resources eligible for new capacity and retirements
				eNgExistingCap[y] + vNGCAP[y] - vNGRETCAP[y]
		elseif y in setdiff(NEW_CAP, RET_CAP) # Resources eligible for only new capacity
				eNgExistingCap[y] + vNGCAP[y]
		elseif y in setdiff(RET_CAP, NEW_CAP) # Resources eligible for only capacity retirements
				eNgExistingCap[y] - vNGRETCAP[y]
		else # Resources not eligible for new capacity or retirements
			    eNgExistingCap[y] + EP[:vZERO]
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new capacity, fixed costs are only O&M costs
	@expression(EP, eNgCFix[y in 1:R],
		if y in NEW_CAP # Resources eligible for new capacity 
            dfRes[y,:InvCost_per_MMBTU_day]*vNGCAP[y] + dfRes[y,:Fixed_OM_Cost_per_MMBTU_day]*eNgTotalCap[y]
		else
			dfRes[y,:Fixed_OM_Cost_per_MMBTU_day]*eNgTotalCap[y]
		end
	)

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eNgTotalCFix, sum(eNgCFix[y] for y in 1:R))

	# Add term to objective function expression
	EP[:eObj] += eNgTotalCFix
	
	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cNgMaxRetNoCommit[y in RET_CAP], vNGRETCAP[y] <= eNgExistingCap[y])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated where Existing_Cap_MMBTU_day is >= Max_Cap_MMBTU_day and lead to infeasabilty
	@constraint(EP, cNgMaxCap[y in intersect(dfRes[dfRes.Max_Cap_MMBTU_day.>0,:R_ID], 1:R)], eNgTotalCap[y] <= dfRes[y,:Max_Cap_MMBTU_day])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated where Existing_Cap_MMBTU_day is <= Min_Cap_MMBTU_day and lead to infeasabilty
	@constraint(EP, cNgMinCap[y in intersect(dfRes[dfRes.Min_Cap_MMBTU_day.>0,:R_ID], 1:R)], eTotalCap[y] >= dfRes[y,:Min_Cap_MMBTU_day])


end
