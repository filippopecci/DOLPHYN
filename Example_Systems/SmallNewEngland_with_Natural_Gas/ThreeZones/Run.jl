"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

# Walk into current directory
cd(dirname(@__FILE__))

# Loading settings
using YAML

settings_path = joinpath(pwd(), "Settings")

genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
hsc_settings = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC model
ng_settings = joinpath(settings_path, "ng_settings.yml") #Settings YAML file path for NG model
mysetup_genx = YAML.load(open(genx_settings)) # mysetup dictionary stores GenX-specific parameters
mysetup_hsc = YAML.load(open(hsc_settings)) # mysetup dictionary stores H2 supply chain-specific parameters
mysetup_ng = YAML.load(open(ng_settings)) # mysetup dictionary stores NG-specific parameters
global_settings = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
mysetup_global = YAML.load(open(global_settings)) # mysetup dictionary stores global settings
mysetup = Dict()
mysetup = merge(mysetup_ng, mysetup_hsc, mysetup_genx, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings

# Start logging
using LoggingExtras

global Log = mysetup["Log"]

if Log
    logger = FileLogger(mysetup["LogFile"])
    global_logger(logger)
end

# # Activate environment
# environment_path = "../../../package_activate.jl"
# if !occursin("DOLPHYNJulEnv", Base.active_project())
#     include(environment_path) #Run this line to activate the Julia virtual environment for GenX; skip it, if the appropriate package versions are installed
# end

### Set relevant directory paths
src_path = "../../../src/"

inpath = pwd()

### Load DOLPHYN
println("Loading packages")
push!(LOAD_PATH, src_path)

using DOLPHYN

## Cluster time series inputs if necessary and if specified by the user
TDRpath = joinpath(inpath, mysetup["TimeDomainReductionFolder"])
if mysetup["TimeDomainReduction"] == 1
    if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv"))
        print_and_log("Clustering Time Series Data...")
        cluster_inputs(inpath, settings_path, mysetup);
        if mysetup["ModelH2"]==1
            h2_inherit_clusters(inpath,mysetup);
        end
        if mysetup["ModelNG"]==1
            ng_inherit_clusters(inpath,mysetup);
        end
    else
        print_and_log("Time Series Data Already Clustered.")
    end

end

# ### Configure solver
print_and_log("Configuring Solver")
OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

#### Running a case

### Load power system inputs
print_and_log("Loading Inputs")
myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters
myinputs = load_inputs(mysetup, inpath)

### Load inputs for modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inpath)
end

# ### Load inputs for modeling the natural gas transport model
if mysetup["ModelNG"]==1
    myinputs = load_ng_inputs(myinputs, mysetup, inpath)
end

### Generate model
print_and_log("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER);

### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
outpath = "$inpath/Results"
write_outputs(EP, outpath, mysetup, myinputs);

# Write hydrogen supply chain outputs
if mysetup["ModelH2"] == 1   
    write_HSC_outputs(EP, outpath, mysetup, myinputs)
end

# Write natural gas outputs
if mysetup["ModelNG"]==1
    write_NG_outputs(EP,outpath,mysetup,myinputs)
end