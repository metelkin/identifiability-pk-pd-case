using HetaSimulator, Plots, StatsPlots
using CSV, DataFrames

p = load_platform("model")
m = p |> models |> first |> last

scn0 = Scenario(m, (0., 120.); parameters = [
    :dose1 => 30.,
    :period1 => 8.,
], observables = [
    :drug_c,
    :pd_output_1,
], events_save = (false, false))
sim(scn0) |> plot
add_scenarios!(p, [:scn0=>scn0]) 

# load optimal parameters
params_df = CSV.read("output/identifiability-intervals.csv", DataFrame)
params_opt = Symbol.(params_df.parameter) .=> params_df.optimal

res0 = sim(scn0; parameters = params_opt)
fig0 = plot(res0; legend = false, grid = false)
savefig(fig0, "output/1E-predicted.png")