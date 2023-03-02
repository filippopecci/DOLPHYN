function ng_pipelines!(EP,inputs,setup)

    print_and_log("Natural Gas Pipelines Module")
    
    df = inputs["dfNGRes"];
    K = inputs["ngPipes"]
    ngT = inputs["ng_T"]     # Number of time steps (days)
	Z = inputs["Z"]     # Number of zones - assumed to be same for power, hydrogen, and natural gas system

    Pipe_IMP = inputs["ng_Pipe_IMP"];#Index set of pipe import resources

    # Natural gas flow in each pipe and day (uni-directional pipes)
    @variable(EP, vNGFLOW[k=1:K,t=1:ngT]>=0)

    # Maximum natural gas flow in each pipe
    @constraint(EP,cNgMaxFlow[k=1:K,t=1:ngT],vNGFLOW[k,t] <= EP[:eNgAvail_Pipe_Cap][k])
 
    # Maximum allowed pipe import by resource "y" at day "t"
    @constraint(EP,cNgMaxPipeImport[y in Pipe_IMP,t=1:ngT], EP[:vNG][y,t]<= EP[:eNgTotalCapPipeImport][y])

    ## Natural Gas Balance Expressions ##
	@expression(EP, eNgBalancePipeImport[t=1:ngT, z=1:Z], sum(EP[:vNG][y,t] for y in intersect(Pipe_IMP, df[df[!,:Zone].==z,:R_ID])))

    @expression(EP, eNgNet_Export_Flows[z=1:Z,t=1:ngT], sum(inputs["ngNet_Map"][k,z] * vNGFLOW[k,t] for k=1:K));

    @expression(EP, eNgBalanceNetExportFlows[t=1:ngT, z=1:Z], -eNgNet_Export_Flows[z,t]);

    EP[:eNgBalance] += eNgBalancePipeImport + eNgBalanceNetExportFlows;

    # Cost of natural gas imports by resource "y" at day "t"
    @expression(EP,eNgCVar_pipe_import[y in Pipe_IMP,t=1:ngT],inputs["ng_omega"][t]*df[y,:Pipe_Import_Cost_per_MMBTU]*EP[:vNG][y,t])

    @expression(EP,eNgTotalCVarPipeImportT[t=1:ngT],sum(eNgCVar_pipe_import[y,t] for y in Pipe_IMP))

    @expression(EP,eNgTotalCVarPipeImport,sum(eNgTotalCVarPipeImportT[t] for t in 1:ngT))

    EP[:eObj] += eNgTotalCVarPipeImport;

end