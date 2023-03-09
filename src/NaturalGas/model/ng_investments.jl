function ng_investments!(EP,inputs,setup)

    print_and_log("Natural Gas Investment Module")

    df = inputs["dfNGRes"];

    R = inputs["ng_R"]; #number of natural gas resources

    STOR = inputs["ng_STOR"];#Index set of storage resources

    SOURCE = inputs["ng_SOURCE"];#Index set of import resources

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

    STOR_LNG_TERM = union(STOR,LNG_TERM);

    NO_NEW_BUILD = SOURCE;# union(SOURCE,LNG_TERM);

    NO_RETIRE = [];#STOR_LNG_TERM;

    K = inputs["ngPipes"]

    # New installed capacity of resource "y"
	@variable(EP, vNGCAP[y in 1:R] >= 0);

	# Retired capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAP[y in 1:R] >= 0);

	# Retired storage capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPSTOR[y in STOR_LNG_TERM] >= 0);

    # New installed storage capacity of resource "y"
	@variable(EP, vNGCAPSTOR[y in STOR_LNG_TERM] >= 0);
    
	# Retired charge capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPCHARGE[y in STOR_LNG_TERM] >= 0);

    # New installed charge capacity of resource "y"
	@variable(EP, vNGCAPCHARGE[y in STOR_LNG_TERM] >= 0);
    
    ###### Capacity investments ####################################################

    @expression(EP,eNgExistingCap[y in 1:R],df[y,:Existing_Cap_MMBTU_day]);

    @expression(EP,eNgExistingCapStor[y in STOR_LNG_TERM],df[y,:Existing_Cap_MMBTU]);

    @expression(EP,eNgExistingCapCharge[y in STOR_LNG_TERM],df[y,:Existing_Charge_Cap_MMBTU_day]);

    @expression(EP,eNgExistingCapPipe[k=1:K], inputs["ngPipeFlow_Max"][k])    

    # Total capacity of resource "y"
    @expression(EP, eNgTotalCap[y in 1:R], eNgExistingCap[y] + vNGCAP[y] - vNGRETCAP[y])

    # Total storage capacity of resource "y"
    @expression(EP, eNgTotalCapStor[y in STOR_LNG_TERM], eNgExistingCapStor[y] + vNGCAPSTOR[y] - vNGRETCAPSTOR[y])

    # Total charge capacity of resource "y"
    @expression(EP, eNgTotalCapCharge[y in STOR_LNG_TERM], eNgExistingCapCharge[y] + vNGCAPCHARGE[y] - vNGRETCAPCHARGE[y])

    # Total pipe transport capacity
    @expression(EP, eNgAvail_Pipe_Cap[k=1:K], eNgExistingCapPipe[k])

    ###### Costs ###################################################################################

    # Fixed costs for every resource "y"
    @expression(EP, eNgCFix[y in 1:R], df[y,:Fixed_OM_Cost_per_MMBTU_day]*eNgTotalCap[y] + df[y,:InvCost_per_MMBTU_day]*vNGCAP[y])
    
    # Total fixed cost of injection
    @expression(EP, eNgTotalCFix, sum(eNgCFix[y] for y in 1:R))

    # Fixed costs of storage for every resource "y"
    @expression(EP, eNgCFixStor[y in STOR_LNG_TERM], df[y,:Fixed_OM_Cost_per_MMBTU]*eNgTotalCapStor[y] + df[y,:InvCost_per_MMBTU]*vNGCAPSTOR[y])

    # Total fixed cost of storage
    @expression(EP, eNgTotalCFixStor, sum(eNgCFixStor[y] for y in STOR_LNG_TERM))

    
    EP[:eObj] += eNgTotalCFixStor + eNgTotalCFix;

    @constraint(EP,cNgMaxRet[y in 1:R], vNGRETCAP[y] <= eNgExistingCap[y])

    @constraint(EP,cNgMaxRetStor[y in STOR_LNG_TERM], vNGRETCAPSTOR[y] <= eNgExistingCapStor[y])

    @constraint(EP,cNgMaxRetCharge[y in STOR_LNG_TERM], vNGRETCAPCHARGE[y] <= eNgExistingCapCharge[y])

    
    # Constraints on retired capacity   
    @constraint(EP,cNgNoRet[y in NO_RETIRE], vNGRETCAP[y] ==0)

    # Constraints on retired storage capacity  
    @constraint(EP,cNgNoRetStor[y in NO_RETIRE], vNGRETCAPSTOR[y] ==0)

    # Constraints on retired charge capacity  
    @constraint(EP,cNgNoRetCharge[y in NO_RETIRE], vNGRETCAPCHARGE[y] ==0)


    # Constraints on new capacity
    @constraint(EP,cNgMaxNew[y in NO_NEW_BUILD], vNGCAP[y]==0)

    if !isempty(intersect(NO_NEW_BUILD,STOR_LNG_TERM))
        # Constraints on new storage capacity
        @constraint(EP,cNgMaxStorNew[y in intersect(NO_NEW_BUILD,STOR_LNG_TERM)], vNGCAPSTOR[y]==0)
    end

    # Constraints on new charge capacity
    @constraint(EP,cNgMaxChargeNew[y in STOR_LNG_TERM], vNGCAPCHARGE[y]==0)

end