function ng_inherit_clusters(path, setup)

    data_directory = joinpath(path, setup["TimeDomainReductionFolder"]);

    if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	  end

    df_load = CSV.read(data_directory*sep*"load_data.csv",DataFrame);
    Period_map =  CSV.read(data_directory*sep*"Period_map.csv",DataFrame);
    Rep_Period_Indices = unique(Period_map[!,:Rep_Period_Index]);
    
    TimestepsPerRepPeriod = Int(df_load[1,:Timesteps_per_Rep_Period]/24);

    rep_timesteps=[];
    T = 1:length(Period_map[!,:Period_Index])*TimestepsPerRepPeriod;
    
    for k in Rep_Period_Indices
        c = Period_map[findfirst(Period_map[!,:Rep_Period_Index].==k),:Rep_Period];
        append!(rep_timesteps,T[(c-1)*TimestepsPerRepPeriod + 1:c*TimestepsPerRepPeriod]);
    end

    NG_demand_all = CSV.read(path*sep*"NG_demand.csv",DataFrame);
    NG_demand = NG_demand_all[rep_timesteps,:];
    NG_demand[1,:VOLL] = NG_demand_all[1,:VOLL];
    NG_demand[1,:Demand_Segment] = NG_demand_all[1,:Demand_Segment];
    NG_demand[1,:Cost_of_Demand_Curtailment_per_MMBTU] = NG_demand_all[1,:Cost_of_Demand_Curtailment_per_MMBTU];
    NG_demand[1,:Max_Demand_Curtailment] = NG_demand_all[1,:Max_Demand_Curtailment];
    NG_demand[1,:CO2_tons_per_MMBTU] = NG_demand_all[1,:CO2_tons_per_MMBTU];
    NG_demand[1,:Rep_Periods] = length(Rep_Period_Indices);
    NG_demand[1,:Timesteps_per_Rep_Period] = TimestepsPerRepPeriod;
    NG_demand[1:length(Rep_Period_Indices),:Sub_Weights] = df_load[1:length(Rep_Period_Indices),:Sub_Weights]/24; #this should be the number of days represented by each cluster
    NG_demand[!,:Time_Index] = 1:length(rep_timesteps);

    CSV.write(data_directory*sep*"NG_demand.csv",NG_demand)

end