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

    df_fill = write_storage_filling(EP,path,setup,inputs);

    df_soc = write_storage_level(EP,path,setup,inputs);

    df_wdw = write_storage_withdrawal(EP,path,setup,inputs);

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

    df = DataFrame([["AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [(vNGFLOW*inputs["ng_omega"])'; vNGFLOW']],["Pipe";inputs["ngPipelinePath"]])

    CSV.write(path*"/ng_pipes.csv",df)

    return df
end

function write_nonserved(EP,path,setup,inputs)

    eNgBalanceNS = value.(EP[:eNgBalanceNS])';

    df = DataFrame([["AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [(eNgBalanceNS*inputs["ng_omega"])'; eNgBalanceNS']],["Zone";["z$i" for i in 1:inputs["Z"]]])

    CSV.write(path*"/ng_nonserved.csv",df)
    return df
end


function write_storage_withdrawal(EP,path,setup,inputs)

    WDW = inputs["ng_WDW"]; # Index set of liquefaction resources

    vNGWDW = value.(EP[:vNGWDW].data);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][WDW,:Zone])); (vNGWDW*inputs["ng_omega"])'; vNGWDW']],["Resource";inputs["dfNGRes"][WDW,:Resource]]);

    CSV.write(path*"/ng_storage_wdw.csv",df)

    return df
end



function write_storage_level(EP,path,setup,inputs)

    SV = inputs["ng_STOR"]; # Index set of storage resources

    vNGFILL = value.(EP[:vNGFILL].data);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][SV,:Zone])); (vNGFILL*inputs["ng_omega"])'; vNGFILL']],["Resource";inputs["dfNGRes"][SV,:Resource]]);

    CSV.write(path*"/ng_storage_level.csv",df)

    return df
end



function write_storage_filling(EP,path,setup,inputs)

    SV = inputs["ng_STOR"]; # Index set of storage resources

    vNGSTORIN = value.(EP[:vNGSTORIN].data);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][SV,:Zone])); (vNGSTORIN*inputs["ng_omega"])'; vNGSTORIN']],["Resource";inputs["dfNGRes"][SV,:Resource]]);

    CSV.write(path*"/ng_storage_in.csv",df)

    return df
end



function write_injections(EP,path,setup,inputs)

    vNG = value.(EP[:vNG]);

    df = DataFrame([["Zone";"AnnualSum";["t$i" for i in 1:inputs["ng_T"]]] [Int.(permutedims(inputs["dfNGRes"][!,:Zone])); (vNG*inputs["ng_omega"])'; vNG']],["Resource";inputs["dfNGRes"].Resource]);

    CSV.write(path*"/ng_injections.csv",df)
    
    return df
 
end

function write_capacity(EP,path,setup,inputs)

    df = DataFrame([inputs["dfNGRes"][!,:Resource]],["Resource"])

    df[!,:Zone] = inputs["dfNGRes"][!,:Zone];
    
    df[!,:StartStorCap].=0.0;
    df[!,:RetStorCap].=0.0;
    df[!,:NewStorCap].=0.0;
    df[!,:EndStorCap].=0.0;

    df[!,:StartStorInjCap].=0.0;
    df[!,:RetStorInjCap].=0.0;
    df[!,:NewStorInjCap].=0.0;
    df[!,:EndStorInjCap].=0.0;

    df[!,:StartStorWdwCap].=0.0;
    df[!,:RetStorWdwCap].=0.0;
    df[!,:NewStorWdwCap].=0.0;
    df[!,:EndStorWdwCap].=0.0;

    df[!,:StartImpCap].=0.0;
    df[!,:RetImpCap].=0.0;
    df[!,:NewImpCap].=0.0;
    df[!,:EndImpCap].=0.0;

    STOR = inputs["ng_STOR"]; # Index set of storage resources
    WDW = inputs["ng_WDW"]; # Index set of withdrawing resources
    Pipe_IMP = inputs["ng_Pipe_IMP"]; #Index set of import resources

    for y in STOR
        df[y,:StartStorCap]= value(EP[:eNgExistingCapStor][y]);
        df[y,:RetStorCap] = value(EP[:vNGRETCAPSTOR][y]);
        df[y,:NewStorCap] = value(EP[:vNGCAPSTOR][y]);
        df[y,:EndStorCap] = value(EP[:eNgTotalCapStor][y])

        df[y,:StartStorInjCap]= value(EP[:eNgExistingCapStorInj][y]);
        df[y,:RetStorInjCap]= value(EP[:vNGRETCAPINJ][y]);
        df[y,:NewStorInjCap]= value(EP[:vNGCAPINJ][y]);
        df[y,:EndStorInjCap]= value(EP[:eNgTotalCapStorInj][y]);


        if y in WDW
            df[y,:StartStorWdwCap]=inputs["dfNGRes"][y,:StorWdwCapacity_MMBTU_day];
            df[y,:RetStorWdwCap]=0;
            df[y,:NewStorWdwCap]=0;
            df[y,:EndStorWdwCap]=value(EP[:eNgTotalCapStorWdw][y]);
        end
    end
    
    for y in Pipe_IMP
        df[y,:StartImpCap]=inputs["dfNGRes"][y,:Max_PipeInflow_MMBTU_day];
        df[y,:RetImpCap]=0;
        df[y,:NewImpCap]=0;
        df[y,:EndImpCap]=value(EP[:eNgTotalCapPipeImport][y]); 
    end

    CSV.write(path*"/ng_capacity.csv",df)

    return df

end