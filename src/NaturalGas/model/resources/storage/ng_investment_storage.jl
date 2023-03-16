function ng_investment_storage!(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Natural Gas Storage Investment Module")

    dfRes = inputs["dfNGRes"]
	MultiStage = setup["MultiStage"]

	STOR_ALL = inputs["ng_STOR_ALL"] # Set of all storage resources
	NEW_CAP_STOR = inputs["ng_NEW_CAP_STOR"] # Set of all storage resources eligible for new capacity
	RET_CAP_STOR = inputs["ng_RET_CAP_STOR"] # Set of all storage resources eligible for capacity retirements

    ### Variables ###
    
    # New installed storage capacity of resource "y"
	@variable(EP, vNGCAPSTOR[y in NEW_CAP_STOR] >= 0)

    # Retired storage capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPSTOR[y in RET_CAP_STOR] >= 0)

    ### Expressions ###

    @expression(EP, eNgExistingCapStor[y in STOR_ALL], dfRes[y,:Existing_Cap_MMBTU])
    
	@expression(EP, eNgTotalCapStor[y in STOR_ALL],
    if (y in intersect(NEW_CAP_STOR, RET_CAP_STOR))
        eNgExistingCapStor[y] + vNGCAPSTOR[y] - vNGRETCAPSTOR[y]
    elseif (y in setdiff(NEW_CAP_STOR, RET_CAP_STOR))
        eNgExistingCapStor[y] + vNGCAPSTOR[y]
    elseif (y in setdiff(RET_CAP_STOR, NEW_CAP_STOR))
        eNgExistingCapStor[y] - vNGRETCAPSTOR[y]
    else
        eNgExistingCapStor[y] + EP[:vZERO]
    end
    )

    ## Objective Function Expressions ##

    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new storage capacity, fixed costs are only O&M costs
    @expression(EP, eNgCFixStor[y in STOR_ALL],
        if y in NEW_CAP_STOR # Resources eligible for new capacity
            dfRes[y,:InvCost_per_MMBTU]*vNGCAPSTOR[y] + dfRes[y,:Fixed_OM_Cost_per_MMBTU]*eNgTotalCapStor[y]
        else
            dfRes[y,:Fixed_OM_Cost_per_MMBTU]*eNgTotalCapStor[y]
        end
    )

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eNgTotalCFixStor, sum(EP[:eNgCFixStor][y] for y in STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eNgTotalCFixStor

    ### Constraints ###

    ## Constraints on retirements and capacity additions
    # Cannot retire more storage capacity than existing capacity
    @constraint(EP, cNgMaxRetStor[y in RET_CAP_STOR], vNGRETCAPSTOR[y] <= eNgExistingCapStor[y])

    ## Constraints on new built storage capacity
    # Constraint on maximum storage capacity (if applicable) [set input to -1 if no constraint on maximum storage capacity]
    # DEV NOTE: This constraint may be violated where Existing_Cap_MMBTU is >= Max_Cap_MMBTU and lead to infeasabilty
    @constraint(EP, cNgMaxCapStor[y in intersect(dfRes[dfRes.Max_Cap_MMBTU.>0,:R_ID], STOR_ALL)], eNgTotalCapStor[y] <= dfRes[y,:Max_Cap_MMBTU])

    # Constraint on minimum storage capacity (if applicable) [set input to -1 if no constraint on minimum storage apacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
    @constraint(EP, cNgMinCapStor[y in intersect(dfRes[dfRes.Min_Cap_MMBTU.>0,:R_ID], STOR_ALL)], eNgTotalCapStor[y] >= dfRes[y,:Min_Cap_MMBTU])

    # Max and min constraints on storage capacity built (as proportion to discharge capacity)
	@constraint(EP,cNgMinCapDuration[y in STOR_ALL], EP[:eNgTotalCapStor][y] >= dfRes[y,:Min_Duration] * EP[:eNgTotalCap][y])

	@constraint(EP,cNgMaxCapDuration[y in STOR_ALL], EP[:eNgTotalCapStor][y] <= dfRes[y,:Max_Duration] * EP[:eNgTotalCap][y])

end