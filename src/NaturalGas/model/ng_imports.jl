function ng_imports!(EP,inputs,setup)

    print_and_log("Natural Gas Import Module")

    df = inputs["dfNGRes"];

	ngT = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones
	ngR = inputs["ng_R"] 	# Number of generators

    IMP = inputs["ng_IMP"];#Index set of import resources

    # Maximum allowed import by resource "y" at day "t"
    @constraint(EP,cNgMaxImport[y in IMP,t=1:ngT], EP[:vNG][y,t]<= EP[:eNgTotalCapImport][y])

    # Cost of natural gas imports by resource "y" at day "t"
    @expression(EP,eNgCVar_import[y in IMP,t=1:ngT],inputs["ng_omega"][t]*df[y,:Import_Cost_per_MMBTU]*EP[:vNG][y,t])

    @expression(EP,eNgTotalCVarImportT[t=1:ngT],sum(eNgCVar_import[y,t] for y in IMP))

    @expression(EP,eNgTotalCVarImport,sum(eNgTotalCVarImportT[t] for t in 1:ngT))

    ## Natural Gas Balance Expressions ##
	@expression(EP, eNgBalanceImport[t=1:ngT, z=1:Z], sum(EP[:vNG][y,t] for y in intersect(IMP, df[df[!,:Zone].==z,:R_ID])))

    EP[:eNgBalance] += eNgBalanceImport;

    EP[:eObj] += eNgTotalCVarImport;


    


end