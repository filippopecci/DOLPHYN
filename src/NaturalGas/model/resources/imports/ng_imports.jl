function ng_imports!(EP::Model,inputs::Dict,setup::Dict)

    print_and_log("Natural Gas Imports Module")

    T = inputs["ng_T"];     # Number of time steps (days)
	Z = inputs["Z"];     # Number of zones - assumed to be same for power, hydrogen, and natural gas system
    SOURCE = inputs["ng_SOURCE"];#Index set of natural gas sources
    R = inputs["ng_R"]; # Number of natural gas resources
    dfRes = inputs["dfNGRes"];

    ## Expressions ##

    # Cost of natural gas import from source "y" at day "t"
    @expression(EP,eNgCVarImport[y in SOURCE,t=1:T],inputs["ng_prices"][dfRes[y,:Import_Price]][t]*EP[:vNG][y,t])

    @expression(EP,eNgTotalCVarImportT[t=1:T],sum(eNgCVarImport[y,t] for y in SOURCE))

    @expression(EP,eNgTotalCVarImport,sum(eNgTotalCVarImportT[t] for t in 1:T))

    EP[:eObj] += eNgTotalCVarImport;

    ## Constraints ##

    # Import capacity constraint
    @constraint(EP,cNgInj[y in SOURCE,t in 1:T],EP[:vNG][y,t]<=EP[:eNgTotalCap][y]);


end