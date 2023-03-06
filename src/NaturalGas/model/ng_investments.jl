function ng_investments!(EP,inputs,setup)

    print_and_log("Natural Gas Investment Module")

    df = inputs["dfNGRes"];

    R = inputs["ng_R"]; #number of natural gas resources

    STOR = inputs["ng_STOR"];#Index set of LNG storage and varporization resources
    WDW = inputs["ng_WDW"];#Index set of withdrawing resources
    Pipe_IMP = inputs["ng_Pipe_IMP"];#Index set of import resources

    K = inputs["ngPipes"]


    #####                                                    #####   
	##### Investments on storage resources: #####
    #####                                                    #####

    @expression(EP, eNgExistingCapStor[y in STOR], df[y,:StorCapacity_MMBTU])

    @expression(EP, eNgExistingCapStorInj[y in STOR], df[y,:StorInjCapacity_MMBTU_day])
	

	# Retired storage capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPSTOR[y in STOR] >= 0);

    # New installed storage capacity of resource "y"
	@variable(EP, vNGCAPSTOR[y in STOR] >= 0);

	# Retired injection capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPINJ[y in STOR] >= 0);

    # New installed injection capacity of resource "y"
	@variable(EP, vNGCAPINJ[y in STOR] >= 0);
    
    # Constraints on retired storage capacity
    @constraint(EP,cNgMaxRetStor[y in STOR], vNGRETCAPSTOR[y] <= eNgExistingCapStor[y])
    
    # Constraints on retired varporization capacity
    @constraint(EP,cNgMaxRetInj[y in STOR], vNGRETCAPINJ[y] <= eNgExistingCapStorInj[y])

    # Total storage capacity of resource "y"
    @expression(EP, eNgTotalCapStor[y in STOR], eNgExistingCapStor[y] + vNGCAPSTOR[y] - vNGRETCAPSTOR[y])

    # Total injection capacity of resource "y"
    @expression(EP, eNgTotalCapStorInj[y in STOR], eNgExistingCapStorInj[y] + vNGCAPINJ[y] - vNGRETCAPINJ[y])

    # Total withdrawing capacity of resource "y" - NO RETIRMENTS OR NEW INSTALLATIONS
    @expression(EP, eNgTotalCapStorWdw[y in WDW], df[y,:StorWdwCapacity_MMBTU_day])

    # Total pipe import capacity of resource "y" - NO RETIRMENTS OR NEW INSTALLATIONS
    @expression(EP, eNgTotalCapPipeImport[y in Pipe_IMP], df[y,:Max_PipeInflow_MMBTU_day])

    # Fixed costs of storage for every STOR resource "y"
    @expression(EP,eNgCFixStor[y in STOR], df[y,:Fixed_OM_Cost_per_MMBTU]*eNgTotalCapStor[y] + df[y,:InvCost_per_MMBTU]*vNGCAPSTOR[y])

    # Fixed costs of injection for every STOR resource "y"
    @expression(EP,eNgCFixStorInj[y in STOR], df[y,:Fixed_OM_Cost_per_MMBTUday]*eNgTotalCapStorInj[y] + df[y,:InvCost_per_MMBTUday]*vNGCAPINJ[y])

    # Total fixed cost of storage
    @expression(EP, eNgTotalCFixStor, sum(eNgCFixStor[y] for y in STOR))

    # Total fixed cost of injection
    @expression(EP, eNgTotalCFixStorInj, sum(eNgCFixStorInj[y] for y in STOR))

    #####                                       #####   
	##### Investments on natural gas pipelines: #####
    #####                                       #####

    @expression(EP,eNgAvail_Pipe_Cap[k=1:K], inputs["ngPipeFlow_Max"][k])

    EP[:eObj] += eNgTotalCFixStor + eNgTotalCFixStorInj;

end