using HetaSimulator, Plots, StatsPlots
using CSV, DataFrames
using Random, Distributions

p = load_platform("model")
m = p |> models |> first |> last

scn0 = Scenario(m, (0., 120.); parameters = [
    :dose1 => 100.,
    :period1 => 0.,
], observables = [
    :drug_c,
    :pd_output_1,
], saveat = [
    1., 2., 4., 8., 24., 48., 96.,
], events_save = (false, false))
add_scenarios!(p, [:scn0=>scn0])

# plot just dots
res0 = sim(scn0)
fig0 = plot(res0, seriestype = :scatter)
savefig(fig0, "output/true-output.png")

res0_df = res0 |> DataFrame

# add some noise to simulate observations
Random.seed!(1234)
norm1 = rand(Normal(0., 0.3), nrow(res0_df))
norm2 = rand(Normal(0., 1.), nrow(res0_df))
res0_df[!, :drug_c] = res0_df.drug_c .* exp.(norm1)
res0_df[!, :pd_output_1] = res0_df.pd_output_1 .+ norm2

# orange and blue dots
fig1 = @df res0_df plot(:t, [:drug_c, :pd_output_1];
    label = ["drug_c" "pd_output_1"],
    seriestype = :scatter,
    xlim = (-5., 125.),
    ylim = (-1., 21.),
    legend = false,
    #xlabel = "time",
    #ylabel = "output",
    grid = false,
    #color = [:blue, :orange],
    markersize = 6,
    tickfontsize = 13,
    guidefontsize = 18
)
savefig(fig1, "output/1A-noisy-output.png")

# save the simulated data in experimental data format
long_df = stack(res0_df, [:drug_c, :pd_output_1], variable_name="prob.mean", value_name="measurement")
long_df[!, "scenario"] .= :scn0
long_df[!, "prob.type"] .= ifelse.(long_df[!, "prob.mean"] .== "drug_c", :lognormal, :normal)

# unknown sigma
long_df[!, "prob.sigma"] .= ifelse.(long_df[!, "prob.mean"] .== "drug_c", "sigma1", "sigma2")
#CSV.write("data/data-synthetic-unknown-sigma.csv", long_df)

# known sigma
long_df[!, "prob.sigma"] .= ifelse.(long_df[!, "prob.mean"] .== "drug_c", 0.3, 1.0)
#CSV.write("data/data-synthetic-known-sigma.csv", long_df)