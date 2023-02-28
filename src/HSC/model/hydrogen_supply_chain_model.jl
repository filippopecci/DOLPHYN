function hydrogen_supply_chain_model!(EP,inputs,setup)


	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power and hydrogen system

    # Initialize Hydrogen Balance Expression
	# Expression for "baseline" H2 balance constraint
	@expression(EP, eH2Balance[t=1:T, z=1:Z], 0)

    # Net Power consumption by HSC supply chain by z and timestep - used in emissions constraints
    @expression(EP, eH2NetpowerConsumptionByAll[t=1:T,z=1:Z], 0)	

    # Infrastructure
    EP = h2_outputs(EP, inputs, setup)

    # Investment cost of various hydrogen generation sources
    EP = h2_investment(EP, inputs, setup)

    if !isempty(inputs["H2_GEN"])
        #model H2 generation
        EP = h2_production(EP, inputs, setup)   
    end

    # Direct emissions of various hydrogen sector resources
    EP = emissions_hsc(EP, inputs,setup)

    # Model H2 non-served
    EP = h2_non_served(EP, inputs,setup)

    # Model hydrogen storage technologies
    if !isempty(inputs["H2_STOR_ALL"])
        EP = h2_storage(EP,inputs,setup)
    end

    if !isempty(inputs["H2_FLEX"])
        #model H2 flexible demand resources
        EP = h2_flexible_demand(EP, inputs, setup)
    end

    if setup["ModelH2Pipelines"] == 1
        # model hydrogen transmission via pipelines
        EP = h2_pipeline(EP, inputs, setup)
    end

    if setup["ModelH2Trucks"] == 1
        # model hydrogen transmission via trucks
        EP = h2_truck(EP, inputs, setup)
    end

    if setup["ModelH2G2P"] == 1
        #model H2 Gas to Power
        EP = h2_g2p(EP, inputs, setup)
    end

end