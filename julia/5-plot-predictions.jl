using Plots, StatsPlots
using CSV, DataFrames
plotlyjs()

prediction_bands_df = CSV.read("output/prediction-bands.csv", DataFrame)

# fig 2E
fig2e = plot(
    
)

savefig(fig2e, "output/2E-predicted.png")
