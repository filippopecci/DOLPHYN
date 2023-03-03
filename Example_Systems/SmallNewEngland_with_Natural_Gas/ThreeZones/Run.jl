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
setup_genx = YAML.load(open(genx_settings)) # setup dictionary stores GenX-specific parameters
setup_hsc = YAML.load(open(hsc_settings)) # setup dictionary stores H2 supply chain-specific parameters
setup_ng = YAML.load(open(ng_settings)) # setup dictionary stores NG-specific parameters
global_settings = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
setup_global = YAML.load(open(global_settings)) # setup dictionary stores global settings
setup = Dict()
setup = merge(setup_ng, setup_hsc, setup_genx, setup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings

# Start logging
using LoggingExtras

global Log = setup["Log"]

if Log
    logger = FileLogger(setup["LogFile"])
    global_logger(logger)
end

# # Activate environment
# environment_path = "../../../package_activate.jl"
# if !occursin("DOLPHYNJulEnv", Base.active_project())
#     include(environment_path) #Run this line to activate the Julia virtual environment for GenX; skip it, if the appropriate package versions are installed
# end

### Set relevant directory paths
src_path = "../../../src/"

path = pwd()

### Load DOLPHYN
println("Loading packages")
push!(LOAD_PATH, src_path)

using DOLPHYN

## Cluster time series inputs if necessary and if specified by the user
TDRpath = joinpath(path, setup["TimeDomainReductionFolder"])
if setup["TimeDomainReduction"] == 1
    if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv"))
        print_and_log("Clustering Time Series Data...")
        cluster_inputs(path, settings_path, setup);
        if setup["ModelH2"]==1
            h2_inherit_clusters(path,setup);
        end
    else
        print_and_log("Time Series Data Already Clustered.")
    end

end

# ### Configure solver
print_and_log("Configuring Solver")
OPTIMIZER = configure_solver(setup["Solver"], settings_path)

#### Running a case

### Load power system inputs
print_and_log("Loading Inputs")
inputs = Dict() # inputs dictionary will store read-in data and computed parameters
inputs = load_inputs(setup, path)

### Load inputs for modeling the hydrogen supply chain
if setup["ModelH2"] == 1
    inputs = load_h2_inputs(inputs, setup, path)
end

# ### Load inputs for modeling the natural gas transport model
if setup["ModelNG"]==1
    inputs = load_ng_inputs(inputs, setup, path)
end

### Generate model
print_and_log("Generating the Optimization Model")
EP = generate_model(setup, inputs, OPTIMIZER);

### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, setup)
inputs["solve_time"] = solve_time # Store the model solve time in inputs

### Write power system output

print_and_log("Writing Output")
outpath = "$path/Results"
write_outputs(EP, outpath, setup, inputs);

# Write hydrogen supply chain outputs
if setup["ModelH2"] == 1   
    write_HSC_outputs(EP, outpath, setup, inputs)
end

# Write natural gas outputs
if setup["ModelNG"]==1
    write_NG_outputs(EP,outpath,setup,inputs)
end