function natural_gas_model!(EP::Model,inputs::Dict,setup::Dict)

   print_and_log("Adding Natural Gas Model")

   T = inputs["ng_T"];     # Number of time steps (days)
	Z = inputs["Z"];     # Number of zones - assumed to be same for power, hydrogen, and natural gas system

   R = inputs["ng_R"]; # Number of natural gas resources

   # Initialize Natural Gas Balance Expression for "baseline" natural gas balance constraint
	@expression(EP, eNgBalance[t=1:T, z=1:Z], 0)

   ng_discharge!(EP,inputs,setup);

   ng_investment_discharge!(EP,inputs,setup);

   ng_demand_curtailment!(EP,inputs,setup);

   ng_pipelines!(EP,inputs,setup);
 
   ng_emissions!(EP,inputs,setup);

   ng_imports!(EP,inputs,setup);
      
   ng_lng_terminals!(EP,inputs,setup);
   
   ng_storage!(EP,inputs,setup);

   ng_to_power!(EP,inputs,setup);

   if setup["ModelH2"]==1
      ng_to_hydrogen!(EP,inputs,setup);
   end

end