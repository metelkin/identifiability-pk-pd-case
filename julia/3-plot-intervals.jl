using Plots, StatsPlots
using CSV, DataFrames
#plotlyjs()
#gr()

## plot fig 1C,2C 

intervals_df = CSV.read("output/identifiability-intervals.csv", DataFrame)

# forest plot
x = log10.(intervals_df.optimal)
y = 1:nrow(intervals_df)

xerr_left  = x .- (ifelse.(ismissing.(intervals_df.lower_bound), 1e-4, intervals_df.lower_bound) .|> log10)
xerr_right = (ifelse.(ismissing.(intervals_df.upper_bound), 1e4, intervals_df.upper_bound) .|> log10) .- x

# Create plot
using LaTeXStrings
ylabels = [L"\theta_{%$i}" for i in 1:nrow(intervals_df)]
fig2c = scatter(x, y;
    #xerror = (xerr_left, xerr_right),
    yflip = true,
    legend = false,
    grid = false,
    yforeground_color_axis = :transparent,
    yticks = (y, ylabels),
    ytick_direction = :none,# remove tick marks
    #xaxis = false,
    markerstrokewidth = 2,
    xlim = (-3.5, 3.1),
    ylim = (0., 8.0),
    xticks = ([-3, 0, 3], ["1e-3", "1e0", "1e3"]),
    markercolor = :grey,
    size = (1000, 400),

    markersize = 10,
    xtickfontsize = 18,
    ytickfontsize = 22,
    guidefontsize = 18
)
savefig(fig2c, "output/1C-identifiability-intervals-forest-plot.png")

fig2c = scatter(x, y;
    xerror = (xerr_left, xerr_right),
    yflip = true,
    legend = false,
    grid = false,
    yforeground_color_axis = :transparent,
    yticks = (y, ylabels),
    ytick_direction = :none,# remove tick marks
    #xaxis = false,
    markerstrokewidth = 2,
    xlim = (-3.5, 3.1),
    ylim = (0., 8.0),
    xticks = ([-3, 0, 3], ["1e-3", "1e0", "1e3"]),
    markercolor = [
        :green, :green, :green, :green, :red, :green, :red,
        :black, :black, :black, :black, :black, :black, :black,
        :black, :black, :black, :black, :black, :black, :black,
    ],
    size = (1000, 400),

    markersize = 10,
    xtickfontsize = 18,
    ytickfontsize = 22,
    guidefontsize = 18
)
savefig(fig2c, "output/2C-identifiability-intervals-forest-plot.png")