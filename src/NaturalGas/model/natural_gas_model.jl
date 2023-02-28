function natural_gas_model!(EP,inputs,setup)

   T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power and hydrogen system

   # Initialize Natural Gas Balance Expression
	# Expression for "baseline" natural gas balance constraint
	@expression(EP, eNgBalance[t=1:T, z=1:Z], 0)

   ng_investments!(EP,inputs,setup);
   


end