function ng_storage_symmetric!(EP::Model, inputs::Dict, setup::Dict)
	# Set up additional variables, constraints, and expressions associated with storage resources with symmetric charge & discharge capacity
	# (e.g. most electrochemical batteries that use same components for charge & discharge)
	# STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

	println("Natural Gas Storage Resources with Symmetric Charge/Discharge Capacity Module")

	dfRes = inputs["dfNGRes"]

	T = inputs["ng_T"]     # Number of time steps (hours)

	STOR_SYMMETRIC = inputs["ng_STOR_SYMMETRIC"]

	### Constraints ###

    # Maximum charging rate must be less than symmetric power rating
	@constraint(EP,cNgMaxChargeRateSymm[y in STOR_SYMMETRIC, t in 1:T], EP[:vNGCHARGE][y,t] <= EP[:eNgTotalCap][y])
    # Max simultaneous charge and discharge cannot be greater than capacity
    @constraint(EP,cNgMaxChargeDischargeSymm[y in STOR_SYMMETRIC, t in 1:T], EP[:vNG][y,t]+EP[:vNGCHARGE][y,t] <= EP[:eNgTotalCap][y])
 



end