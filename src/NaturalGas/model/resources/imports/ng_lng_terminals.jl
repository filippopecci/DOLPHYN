function ng_lng_terminals!(EP::Model, inputs::Dict, setup::Dict)

	println("LNG Terminal Resources Module")

	dfRes = inputs["dfNGRes"]

	T = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

	### Variables ###

	# LNG Terminal storage level of resource "y" at day "t" [MMBTU] on zone "z" - unbounded
	@variable(EP, vNGS_LNG[y in LNG_TERM, t=1:T] >= 0);

	# LNG Terminal import (charge) variable
	@variable(EP, vNGINPUT_LNG[y in LNG_TERM, t=1:T] >= 0)

	### Expressions ###

	## NG Balance Expressions ##
	@expression(EP, eNgLngTerms[t=1:T, z=1:Z], sum(EP[:vNG][y,t] for y in intersect(LNG_TERM, dfRes[(dfRes[!,:Zone].==z),:R_ID])))

	EP[:eNgBalance] += eNgLngTerms

    # Cost of LNG imports by terminal "y" at day "t"
    @expression(EP,eNgCVarLngImport[y in LNG_TERM,t=1:T],inputs["ng_prices"][dfRes[y,:Import_Price]][t]*vNGINPUT_LNG[y,t])

    @expression(EP,eNgTotalCVarLngImportT[t=1:T],sum(eNgCVarLngImport[y,t] for y in LNG_TERM))
        
    @expression(EP,eNgTotalCVarLngImport,sum(eNgTotalCVarLngImportT[t] for t in 1:T))
        
    EP[:eObj] += eNgTotalCVarLngImport;

	### Constratints ###

	# LNG stored in terminal at end of each other day is equal to LNG at end of prior day less discharge + import in the current day
	@constraint(EP,cNgLngTermInterior[y in LNG_TERM, t in 2:T], EP[:vNGS_LNG][y,t] == EP[:vNGS_LNG][y,t-1] - (1/dfRes[y,:Eff_Down]*EP[:vNG][y,t]) + vNGINPUT_LNG[y,t])

    @constraint(EP,cNgLngTermWrapStart[y in LNG_TERM], EP[:vNGS_LNG][y,1] == EP[:vNGS_LNG][y,T] - (1/dfRes[y,:Eff_Down]*EP[:vNG][y,1]) + vNGINPUT_LNG[y,1])

	# Maximum discharging rate must be less than discharge rating OR available stored LNG at start of hour, whichever is less
	@constraint(EP,cNgLngTermMaxDischarge[y in LNG_TERM, t in 1:T], EP[:vNG][y,t] <= EP[:eNgTotalCap][y])

	@constraint(EP,cNgLngTermMaxDischargeInterior[y in LNG_TERM, t in 2:T], EP[:vNG][y,t] <= EP[:vNGS_LNG][y,t-1])

	@constraint(EP,cNgLngTermMaxDischargeStart[y in LNG_TERM, t = 1], EP[:vNG][y,t] <= EP[:vNGS_LNG][y,T])
	



end
