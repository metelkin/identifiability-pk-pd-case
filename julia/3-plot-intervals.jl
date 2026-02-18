using Plots, StatsPlots
using CSV, DataFrames
plotlyjs()

## plot fig 1C,2C 

intervals_df = CSV.read("output/identifiability-intervals.csv", DataFrame)

# forest plot
x = log10.(intervals_df.optimal)
y = 1:nrow(intervals_df)

xerr_left  = x .- (ifelse.(ismissing.(intervals_df.lower_bound), 1e-4, intervals_df.lower_bound) .|> log10)
xerr_right = (ifelse.(ismissing.(intervals_df.upper_bound), 1e4, intervals_df.upper_bound) .|> log10) .- x

# Create plot
fig2c = scatter(x, y,
    #xerror = (xerr_left, xerr_right),
    yflip = true,
    legend = false,
    grid = false,
    foreground_color_axis = :transparent,

    yticks = (y, string.(intervals_df.parameter)),

    tick_direction = :none,# remove tick marks

    #xaxis = false,
    markersize = 4,
    markerstrokewidth = 2,
    tickfontsize = 12,

    xlim = (-3.1, 3.1),
    size = (420, 320),
    xticks = ([-3, 0, 3], ["10<sup>-3</sup>", "10<sup>0</sup>", "10<sup>3</sup>"]),

     markercolor = :grey
)
savefig(fig2c, "output/1C-identifiability-intervals-forest-plot.png")

fig2c = scatter(x, y,
    xerror = (xerr_left, xerr_right),
    yflip = true,
    legend = false,
    grid = false,
    foreground_color_axis = :transparent,

    yticks = (y, string.(intervals_df.parameter)),

    tick_direction = :none,# remove tick marks

    #xaxis = false,
    markersize = 4,
    markerstrokewidth = 2,
    tickfontsize = 12,

    xlim = (-3.1, 3.1),
    size = (420, 320),
    xticks = ([-3, 0, 3], ["10<sup>-3</sup>", "10<sup>0</sup>", "10<sup>3</sup>"]),

     markercolor = [:green, :green, :green, :green, :red, :red, :red, :red, :red, :red]
)
savefig(fig2c, "output/2C-identifiability-intervals-forest-plot.png")