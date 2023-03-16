function ng_storage_asymmetric!(EP::Model, inputs::Dict, setup::Dict)
	# Set up additional variables, constraints, and expressions associated with storage resources with asymmetric charge & discharge capacity
	# (e.g. most chemical, thermal, and mechanical storage options with distinct charge & discharge components/processes)
	# STOR = 2 corresponds to storage with distinct power and energy capacity decisions and distinct charge and discharge power capacity decisions/ratings

	println("Natural Gas Storage Resources with Asmymetric Charge/Discharge Capacity Module")

	dfRes = inputs["dfNGRes"]

	T = inputs["ng_T"]     # Number of time steps (days)

	STOR_ASYMMETRIC = inputs["ng_STOR_ASYMMETRIC"]

	### Constraints ###

	# Maximum charging rate must be less than charge power rating
	@constraint(EP,cNgMaxChargeRateAsymm[y in STOR_ASYMMETRIC, t in 1:T], EP[:vNGCHARGE][y,t] <= EP[:eNgTotalCapCharge][y])
	

end
