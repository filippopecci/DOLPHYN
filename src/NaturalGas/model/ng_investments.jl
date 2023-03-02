function ng_investments!(EP,inputs,setup)

    print_and_log("Natural Gas Investment Module")

    df = inputs["dfNGRes"];

    R = inputs["ng_R"]; #number of natural gas resources

    SV = inputs["ng_STOR"];#Index set of LNG storage and varporization resources
    LIQ = inputs["ng_LIQ"];#Index set of liquefaction resources
    IMP = inputs["ng_IMP"];#Index set of import resources

    K = inputs["ngPipes"]


    #####                                                    #####   
	##### Investments on storage and vaporization resources: #####
    #####                                                    #####

    @expression(EP, eNgExistingCapStor[y in SV], df[y,:StorCapacity_MMBTU])

    @expression(EP, eNgExistingCapVapor[y in SV], df[y,:VaporCapacity_MMBTU_day])
	

	# Retired storage capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPSTOR[y in SV] >= 0);

    # New installed storage capacity of resource "y"
	@variable(EP, vNGCAPSTOR[y in SV] >= 0);

	# Retired vaporization capacity of resource "y" from existing capacity
	@variable(EP, vNGRETCAPVAPOR[y in SV] >= 0);

    # New installed vaporization capacity of resource "y"
	@variable(EP, vNGCAPVAPOR[y in SV] >= 0);
    
    # Constraints on retired storage capacity
    @constraint(EP,cNgMaxRetStor[y in SV], vNGRETCAPSTOR[y] <= eNgExistingCapStor[y])
    
    # Constraints on retired varporization capacity
    @constraint(EP,cNgMaxRetVapor[y in SV], vNGRETCAPVAPOR[y] <= eNgExistingCapVapor[y])

    # Total storage capacity of resource "y"
    @expression(EP, eNgTotalCapStor[y in SV], eNgExistingCapStor[y] + vNGCAPSTOR[y] - vNGRETCAPSTOR[y])

    # Total vaporization capacity of resource "y"
    @expression(EP, eNgTotalCapVapor[y in SV], eNgExistingCapVapor[y] + vNGCAPVAPOR[y] - vNGRETCAPVAPOR[y])

    # Total liquefaction capacity of resource "y" - NO RETIRMENTS OR NEW INSTALLATIONS
    @expression(EP, eNgTotalCapLiquef[y in LIQ], df[y,:LiquefCapacity_MMBTU_day])

    # Total import capacity of resource "y" - NO RETIRMENTS OR NEW INSTALLATIONS
    @expression(EP, eNgTotalCapImport[y in IMP], df[y,:Max_Inflow_MMBTU_day])

    # Fixed costs of storage for every SV resource "y"
    @expression(EP,eNgCFixStor[y in SV], df[y,:Fixed_OM_Cost_per_MMBTU]*eNgTotalCapStor[y] + df[y,:InvCost_per_MMBTU]*vNGCAPSTOR[y])

    # Fixed costs of vaporization for every SV resource "y"
    @expression(EP,eNgCFixVapor[y in SV], df[y,:Fixed_OM_Cost_per_MMBTUday]*eNgTotalCapVapor[y] + df[y,:InvCost_per_MMBTUday]*vNGCAPVAPOR[y])

    # Total fixed cost of storage
    @expression(EP, eNgTotalCFixStor, sum(eNgCFixStor[y] for y in SV))

    # Total fixed cost of vaporization
    @expression(EP, eNgTotalCFixVapor, sum(eNgCFixVapor[y] for y in SV))

    #####                                       #####   
	##### Investments on natural gas pipelines: #####
    #####                                       #####

    @expression(EP,eNgAvail_Pipe_Cap[k=1:K], inputs["ngPipeFlow_Max"][k])

    EP[:eObj] += eNgTotalCFixStor + eNgTotalCFixVapor;

end