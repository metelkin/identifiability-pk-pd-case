using Plots, StatsPlots
using CSV, DataFrames
plotlyjs()

prediction_bands_df = CSV.read("output/prediction-bands.csv", DataFrame)
prediction_bands_df.lower_bound = ifelse.(prediction_bands_df.lower_status .== "SCAN_BOUND_REACHED", 1e-4, prediction_bands_df.lower_bound)
prediction_bands_df.upper_bound = ifelse.(prediction_bands_df.upper_status .== "SCAN_BOUND_REACHED", 40., prediction_bands_df.upper_bound)

# fig 2E
fig2e = plot(
    xlabel = "Time",
    ylabel = "Output",
    xlim = (0., 120.),
    ylim = (0., 25.),
)

for subdf in groupby(prediction_bands_df, :output)
    #subdf = groupby(prediction_bands_df, :output)[1]
    plot!(fig2e, subdf.time_point, subdf.optimal;
        ribbon = (subdf.optimal .- subdf.lower_bound, subdf.upper_bound .- subdf.optimal),
        legend = false,
        grid = false,
        fillalpha = 0.3,
        linewidth = 1
    )
end
fig2e

savefig(fig2e, "output/2E-predicted.png")
