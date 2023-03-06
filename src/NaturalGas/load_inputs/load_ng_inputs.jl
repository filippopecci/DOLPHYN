function load_ng_inputs(inputs,setup,path)

    ## Read input files
	println("Reading Natural Gas Input CSV Files")

    # Read input data about gas network topology, operating and expansion attributes
	if isfile(joinpath(path,"NG_network.csv"))
		inputs = load_ng_network(inputs,setup,path);
	else
		inputs["NG_Pipes"] = 0
	end

    inputs = load_ng_demand(inputs,setup,path);

    inputs = load_ng_resources(inputs,setup,path);

    inputs = load_ng_days_to_power_hours(inputs,setup,path);

    inputs = load_ng_fuel_data(inputs,setup,path);

    println("Natural Gas CSV Files Successfully Read In From $path")

    return inputs

end

function load_ng_fuel_data(inputs,setup,path)

    filename = "Fuels_data.csv"
    file_path = joinpath(path, filename)
    fuels_in = DataFrame(CSV.File(file_path, header=true), copycols=true)

    # Fuel costs & CO2 emissions rate for each fuel type
    fuels = names(fuels_in)[2:end]
    costs = Matrix(fuels_in[2:end, 2:end])
    CO2_content = fuels_in[1, 2:end] # tons CO2/MMBtu
    fuel_costs = Dict{AbstractString, Array{Float64}}()
    fuel_CO2 = Dict{AbstractString, Float64}()

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    for i = 1:length(fuels)
        if in(fuels[i],unique(skipmissing(inputs["dfNGRes"].Fuel_Cost)))
            fuel_costs[fuels[i]] =  [sum(costs[(k-1)*24+1:k*24,i] / scale_factor^2)/24 for k in 1:365]; #cost is in million dollars with scaling, dollars wihtout scaling
            # fuel_CO2 is kton/MMBTU with scaling, or ton/MMBTU without scaling.
            fuel_CO2[fuels[i]] = CO2_content[i] / scale_factor;
        end
    end

    inputs["ng_fuels"] = fuels
    inputs["ng_fuel_costs"] = fuel_costs
    inputs["ng_fuel_CO2"] = fuel_CO2

    println(filename * " Successfully Read!")

    return inputs
end


function load_ng_days_to_power_hours(inputs,setup,path)

    if setup["TimeDomainReduction"]==1
        period_map = "Period_map.csv"
        data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
        file_path = joinpath(data_directory, period_map)
        Period_Map = DataFrame(CSV.File(file_path, header=true), copycols=true)
    else
        Period_Map = DataFrame([[1],[1],[1]], ["Period_Index";"Rep_Period";"Rep_Period_Index"])
    end

    DaysPerPowerPeriod = Int(inputs["hours_per_subperiod"]/24);

    Power_Days=zeros(Int64,DaysPerPowerPeriod*inputs["REP_PERIOD"]);
    T = 1:inputs["ng_T"];
    for k in 1:inputs["REP_PERIOD"]
        c = Period_Map[findfirst(Period_Map[!,:Rep_Period_Index].==k),:Rep_Period];
        Power_Days[(k-1)*DaysPerPowerPeriod+1:k*DaysPerPowerPeriod] = T[(c-1)*DaysPerPowerPeriod + 1:c*DaysPerPowerPeriod];
    end


    corresp_power_day = zeros(Int64,inputs["ng_T"]);
    for i in 1:length(Period_Map.Period_Index)
        idx = Period_Map.Period_Index[i];
        for t in 1:DaysPerPowerPeriod
            corresp_power_day[ (idx-1)*DaysPerPowerPeriod + t] = Power_Days[(Period_Map.Rep_Period_Index[i]-1)*DaysPerPowerPeriod+t]
        end
    end

    if corresp_power_day[end]==0
        corresp_power_day[end] = corresp_power_day[1];
    end

    inputs["ng_PowerDays"] = Power_Days;
    inputs["ng_Corresp_PowerDays"] = corresp_power_day;

    
    return inputs
        
   
end

function load_ng_network(inputs,setup,path)

    filename = "NG_network.csv"
    network_var = DataFrame(CSV.File(joinpath(path, filename), header=true), copycols=true)

    as_vector(col::Symbol) = collect(skipmissing(network_var[!, col]))
    to_floats(col::Symbol) = convert(Array{Float64}, as_vector(col))

    # Number of pipes in the network
    inputs["ngPipes"] = length(as_vector(:Pipes))

    # Topology of the network source-sink matrix
    inputs["ngNet_Map"] = load_network_map(network_var,inputs["Z"], inputs["ngPipes"])

    # Transmission capacity of the network (in MMBTU per day)
    inputs["ngPipeFlow_Max"] = to_floats(:Pipe_Capacity_MMBTU_day);

    inputs["ngPipelinePath"] = as_vector(:Pipeline_Path);

    println(filename * " Successfully Read!")

    return inputs

end


function load_ng_demand(inputs,setup,path)

    # # Load related inputs
	# data_directory = joinpath(path, setup["TimeDomainReductionFolder"]);

    # if setup["TimeDomainReduction"] == 1  &&  (isfile(data_directory*"/Load_data.csv")) && (isfile(data_directory*"/Generators_variability.csv")) && (isfile(data_directory*"/Fuels_data.csv"))
    #     my_dir = data_directory
	# else
    #     my_dir = path
	# end
    my_dir=path;
    filename = "NG_demand.csv"
    file_path = joinpath(my_dir, filename)
    load_in = DataFrame(CSV.File(file_path, header=true), copycols=true)

    as_vector(col::Symbol) = collect(skipmissing(load_in[!, col]))

    # Number of time steps (periods)
    ngT = length(as_vector(:Time_Index))
    # Number of demand curtailment/lost load segments
    ngSEG = length(as_vector(:Demand_Segment))
    ## Set indices for internal use
    inputs["ng_T"] = ngT
    inputs["ng_SEG"] = ngSEG
	Z = inputs["Z"]   # Number of zones

    # Modeling full year chronologically at daily resolution 
	# Total number of periods and subperiods
	inputs["ng_REP_PERIOD"] = convert(Int16, as_vector(:Rep_Periods)[1])
	inputs["ng_H"] = 1;
	inputs["ng_omega"] = ones(Float64, ngT) # weights associated with operational sub-period in the model - sum of weight = 8760

    # Create time set steps indicies
	inputs["ng_days_per_subperiod"] = div.(ngT,inputs["ng_REP_PERIOD"]) # total number of days per subperiod

	days_per_subperiod = inputs["ng_days_per_subperiod"] # set value for internal use

	inputs["ng_START_SUBPERIODS"] = 1:days_per_subperiod:ngT 	# set of indexes for all time periods that start a subperiod (e.g. sample day/week)
	inputs["ng_INTERIOR_SUBPERIODS"] = setdiff(1:ngT, inputs["ng_START_SUBPERIODS"]) # set of indexes for all time periods that do not start a subperiod

    start = findall(s -> s == "z1", names(load_in))[1] #gets the starting column number of all the columns, with header "z1"

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    # Max value of non-served natural gas
    inputs["ng_Voll"] = as_vector(:VOLL)/ scale_factor^2 # convert from $ to million $
    # Demand in MW
    inputs["ng_D"] =Matrix(load_in[1:ngT, start:start+Z-1]);

	# Cost of non-served natural gas/demand curtailment
    # Cost of each segment reported as a fraction of value of non-served natural gas
    inputs["ng_C_D_Curtail"] = as_vector(:Cost_of_Demand_Curtailment_per_MMBTU) * inputs["ng_Voll"][1];
    # Maximum hourly demand curtailable as % of the max demand (for each segment)
    inputs["ng_Max_D_Curtail"] = as_vector(:Max_Demand_Curtailment);

	println(filename * " Successfully Read!")


    return inputs
end

function load_ng_resources(inputs,setup,path)

    filename = "NG_resources.csv"
	res_in = DataFrame(CSV.File(joinpath(path, filename), header=true), copycols=true)

	# Add Resource IDs after reading to prevent user errors
	res_in[!,:R_ID] = 1:length(collect(skipmissing(res_in[!,1])))
    println(names(res_in))
    # When ParameterScale= 1 costs are defined in million $
    if setup["ParameterScale"]==1
       res_in[!,:InvCost_per_MMBTU] = res_in[!,:InvCost_per_MMBTU]/ ModelScalingFactor^2;
       res_in[!,:InvCost_per_MMBTUday] = res_in[!,:InvCost_per_MMBTUday]/ ModelScalingFactor^2;
       res_in[!,:Fixed_OM_Cost_per_MMBTU] = res_in[!,:Fixed_OM_Cost_per_MMBTU]/ ModelScalingFactor^2;
       res_in[!,:Fixed_OM_Cost_per_MMBTUday] = res_in[!,:Fixed_OM_Cost_per_MMBTUday]/ ModelScalingFactor^2;
     end

	# Store DataFrame of generators/resources input data for use in model
	inputs["dfNGRes"] = res_in

	# Number of resources
	inputs["ng_R"] = length(collect(skipmissing(res_in[!,:R_ID])))
    # Set of LNG storage resources
    inputs["ng_STOR"] = res_in[res_in.Storage.==1,:R_ID]
    # Set of natural gas withdrawing resources
    inputs["ng_WDW"] = res_in[res_in.StorWdwCapacity_MMBTU_day.>0,:R_ID]
    # Set of natural gas import resources
    inputs["ng_Pipe_IMP"] = res_in[res_in.Pipe_Import.==1,:R_ID]
    inputs["ng_LNG_IMP"] = res_in[res_in.LNG_Import.==1,:R_ID]
    # Set of power generators using natural gas
    inputs["ng_P_GEN"] = inputs["dfGen"][[occursin("gas",inputs["dfGen"].Resource_Type[n]) for n in 1:inputs["G"]],:R_ID];

    if setup["ModelH2"]==1
        # Set pf hydrogen generators using natural gas
        inputs["ng_H2_GEN"] = inputs["dfH2Gen"][[occursin("SMR",inputs["dfH2Gen"].H2_Resource[n]) for n in 1:size(inputs["dfH2Gen"],1)],:R_ID]
    end

    println(filename * " Successfully Read!")

    return inputs
end


function load_network_map(network_var, Z, K)
    # Topology of the network source-sink matrix
    col = findall(s -> s == "z1", names(network_var))[1]
    mat = Matrix{Float64}(network_var[1:K, col:col+Z-1])
   
    return mat
end