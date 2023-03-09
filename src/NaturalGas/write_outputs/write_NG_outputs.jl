function write_NG_outputs(EP::Model, genx_path::AbstractString, setup::Dict,inputs::Dict)
    
    if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
		# Overwrite existing results if dir exists
		# This is the default behaviour when there is no flag, to avoid breaking existing code
        # Create directory if it does not exist
        path = "$genx_path/Results_NG";
        if !(isdir(path))
            mkpath(path)
        end
	else
		# Find closest unused ouput directory name
		path = choose_ng_output_dir(genx_path)
            # Create directory if it does not exist
        if !(isdir(path))
            mkpath(path)
        end
	end

    df_inj = write_injections(EP,path,setup,inputs);

    df_cap = write_capacity(EP,path,setup,inputs); 

    df_charge = write_storage_charge(EP,path,setup,inputs);

    df_soc = write_storage_level(EP,path,setup,inputs);

    df_ns = write_nonserved(EP,path,setup,inputs);

    df_flow = write_pipe_flows(EP,path,setup,inputs);

    df_ngp = write_ng_to_power(EP,path,setup,inputs);  

    if setup["ModelH2"]==1
        df_ngh2 = write_ng_to_h2(EP,path,setup,inputs);
    end


end


function write_ng_to_h2(EP,path,setup,inputs)

    vNGH2 = value.(EP[:vNGH2].data);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in inputs["ng_PowerDays"]]] [Int.(permutedims(inputs["dfH2Gen"][inputs["ng_H2_GEN"],:Zone])); sum(vNGH2,dims=2)'; vNGH2']],["Resource";inputs["dfH2Gen"][inputs["ng_H2_GEN"],:H2_Resource]]);

    CSV.write(path*"/ng_natural_gas_to_hydrogen.csv",df)

    return df

end


function write_ng_to_power(EP,path,setup,inputs)

    vNGP = value.(EP[:vNGP].data);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in inputs["ng_PowerDays"]]] [Int.(permutedims(inputs["dfGen"][inputs["ng_P_GEN"],:Zone])); sum(vNGP,dims=2)'; vNGP']],["Resource";inputs["dfGen"][inputs["ng_P_GEN"],:Resource]]);

    CSV.write(path*"/ng_natural_gas_to_power.csv",df)

    return df

end

function write_pipe_flows(EP,path,setup,inputs)

    vNGFLOW = value.(EP[:vNGFLOW]);

    df = DataFrame([["AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [sum(vNGFLOW,dims=2)'; vNGFLOW']],["Pipe";inputs["ngPipelinePath"]])

    CSV.write(path*"/ng_pipes.csv",df)

    return df
end

function write_nonserved(EP,path,setup,inputs)

    eNgBalanceNS = value.(EP[:eNgBalanceNS])';

    df = DataFrame([["AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [sum(eNgBalanceNS,dims=2)'; eNgBalanceNS']],["Zone";["z$i" for i in 1:inputs["Z"]]])

    CSV.write(path*"/ng_nonserved.csv",df)
    return df
end


function write_storage_charge(EP,path,setup,inputs)

    STOR = inputs["ng_STOR"]; # Index set of storage resources

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

    vNGCHARGE = value.(EP[:vNGCHARGE].data);

    STOR_LNG_TERM = union(STOR,LNG_TERM);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][STOR_LNG_TERM,:Zone])); sum(vNGCHARGE,dims=2)'; vNGCHARGE']],["Resource";inputs["dfNGRes"][STOR_LNG_TERM,:Resource]]);

    CSV.write(path*"/ng_storage_charge.csv",df)

    return df
end



function write_storage_level(EP,path,setup,inputs)

    STOR = inputs["ng_STOR"]; # Index set of storage resources

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

    vNGSTOR = value.(EP[:vNGSTOR].data);

    STOR_LNG_TERM = union(STOR,LNG_TERM);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][STOR_LNG_TERM,:Zone])); sum(vNGSTOR,dims=2)'; vNGSTOR']],["Resource";inputs["dfNGRes"][STOR_LNG_TERM,:Resource]]);

    CSV.write(path*"/ng_storage_level.csv",df)

    return df
end


function write_injections(EP,path,setup,inputs)

    vNG = value.(EP[:vNG]);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][!,:Zone])); sum(vNG,dims=2)'; vNG']],["Resource";inputs["dfNGRes"].Resource]);

    CSV.write(path*"/ng_injections.csv",df)
    
    return df
 
end

function write_capacity(EP,path,setup,inputs)

    df = DataFrame([inputs["dfNGRes"][!,:Resource]],["Resource"])

    STOR = inputs["ng_STOR"];#Index set of storage resources

    LNG_TERM = inputs["ng_LNG_IMP"]; #Index set of LNG ng_lng_terminals

    STOR_LNG_TERM = union(STOR,LNG_TERM);

    df[!,:Zone] = inputs["dfNGRes"][!,:Zone];
    
    df[!,:StartCap].=0.0;
    df[!,:RetCap].=0.0;
    df[!,:NewCap].=0.0;
    df[!,:EndCap].=0.0;

    df[!,:StartStorCap].=0.0;
    df[!,:RetStorCap].=0.0;
    df[!,:NewStorCap].=0.0;
    df[!,:EndStorCap].=0.0;

    df[!,:StartChargeCap].=0.0;
    df[!,:RetChargeCap].=0.0;
    df[!,:NewChargeCap].=0.0;
    df[!,:EndChargeCap].=0.0;

    for y in 1:size(df,1)


        df[y,:StartCap]= value(EP[:eNgExistingCap][y]);
        df[y,:RetCap] = value(EP[:vNGRETCAP][y]);
        df[y,:NewCap] = value(EP[:vNGCAP][y]);
        df[y,:EndCap] = value(EP[:eNgTotalCap][y])

        if y in STOR_LNG_TERM
            df[y,:StartStorCap]= value(EP[:eNgExistingCapStor][y]);
            df[y,:RetStorCap]= value(EP[:vNGRETCAPSTOR][y]);
            df[y,:NewStorCap]= value(EP[:vNGCAPSTOR][y]);
            df[y,:EndStorCap]= value(EP[:eNgTotalCapStor][y]);

            df[y,:StartChargeCap]= value(EP[:eNgExistingCapCharge][y]);
            df[y,:RetChargeCap]= value(EP[:vNGRETCAPCHARGE][y]);
            df[y,:NewChargeCap]= value(EP[:vNGCAPCHARGE][y]);
            df[y,:EndChargeCap]= value(EP[:eNgTotalCapCharge][y]);
        end
    end
    
    CSV.write(path*"/ng_capacity.csv",df)

    return df

end