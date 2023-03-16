function ng_storage!(EP::Model,inputs::Dict,setup::Dict)

    print_and_log("Natural Gas Storage Module")

    # dfRes = inputs["dfNGRes"];

	# T = inputs["ng_T"]     # Number of time steps (days)
	# Z = inputs["Z"]     # Number of zones
    
    if !isempty(inputs["ng_STOR_ALL"])
        ng_investment_storage!(EP, inputs, setup)
        ng_storage_all!(EP, inputs, setup)
    end

    if !isempty(inputs["ng_STOR_ASYMMETRIC"])
		ng_investment_charge!(EP, inputs, setup)
		ng_storage_asymmetric!(EP, inputs, setup)
	end

	if !isempty(inputs["ng_STOR_SYMMETRIC"])
		ng_storage_symmetric!(EP, inputs, setup)
	end


end