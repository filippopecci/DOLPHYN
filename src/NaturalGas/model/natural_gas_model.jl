function natural_gas_model!(EP,inputs,setup)

   print_and_log("Adding Natural Gas Model")

   ngT = inputs["ng_T"];     # Number of time steps (days)
	Z = inputs["Z"];     # Number of zones - assumed to be same for power, hydrogen, and natural gas system

   ngR = inputs["ng_R"]; # Number of natural gas resources

   ng_investments!(EP,inputs,setup);
   
   # Initialize Natural Gas Balance Expression
	# Expression for "baseline" natural gas balance constraint
	@expression(EP, eNgBalance[t=1:ngT, z=1:Z], 0)

   # Natural gas that is injected by resource "y" at day "t"
   @variable(EP,vNG[y=1:ngR,t=1:ngT]>=0)

   ng_svl!(EP,inputs,setup);
   
   ng_pipelines!(EP,inputs,setup);

   ng_demand_curtailment!(EP,inputs,setup);
   
   ng_to_power!(EP,inputs,setup);
   
   if setup["ModelH2"]==1
      ng_to_hydrogen!(EP,inputs,setup);
   end

end