using HetaSimulator, Plots
using CSV, DataFrames

## load model and scenarios and run mean

p = load_platform("models/01-multicompartment-pkpd")
pool_1 = read_scenarios("models/01-multicompartment-pkpd/scenarios/pool-1.csv")
add_scenarios!(p, pool_1)

#p |> sim |> plot

### load parameters and run simulations ###

parameter_set = read_mcvecs("data/01-multicompartment-pkpd/profile-1/vp-parameters-1.csv")

mc_res = mc(p, parameter_set)

mc_df = mc_res |> DataFrame
CSV.write("data/01-multicompartment-pkpd/profile-1/vp-outputs-personal-1.csv", mc_df)

fig = plot(mc_res)
savefig(fig, "data/01-multicompartment-pkpd/profile-1/vp-outputs-personal-1.png")

#ens = EnsembleSummary(mc_res; quantiles=[0.05,0.95])
#plot(ens)

long_df = stack(mc_df, [:drug_c, :pd_output_1], variable_name=:output)

# mean-sd format for DigiPopData.jl

df = combine(
    groupby(long_df, [:scenario, :output, :t]),
    [:output, :t] => ((x,y) -> string(x[1], "_", lpad(y[1] |> Int, 3, '0'))) => "endpoint",
    :value => mean => "metric.mean",
    :value => std  => "metric.sd",
)

df[!, "metric.type"] .= "mean_sd"
df[!, "id"] .= "m" .* lpad.(string.(1:nrow(df)), 3, '0')

CSV.write("data/01-multicompartment-pkpd/profile-1/vp-outputs-mean_sd-1.csv", df)

## Plots

plots = []

for scn in unique(df.scenario)

    sdf = df[df.scenario .== scn, :]
    sort!(sdf, [:output, :t])

    p = plot(
        xlabel = "Time",
        ylabel = "Value",
        title = "Scenario: $scn",
    )

    for out in unique(sdf.output)

        odf = sdf[sdf.output .== out, :]

        plot!(
            p,
            odf.t,
            odf."metric.mean";
            seriestype = :scatter,
            yerror = odf."metric.sd",
            label = string(out),
        )
    end

    push!(plots, p)
end
final_plot = plot(plots..., layout = (length(plots), 1), size = (800, 300 * length(plots)))

savefig(final_plot, "data/01-multicompartment-pkpd/profile-1/vp-outputs-mean_sd-1.png")

### quartile format for DigiPopData.jl ###

levels = [0.25, 0.5, 0.75]
df = combine(
    groupby(long_df, [:scenario, :output, :t]),
    [:output, :t] => ((x,y) -> string(x[1], "_", lpad(y[1] |> Int, 3, '0'))) => "endpoint",
    :value => (x -> join(quantile(x, levels), ";")) => "metric.values",
)

df[!, "metric.levels"] .= join(levels, ";")
df[!, "metric.type"] .= "quantile"
df[!, "id"] .= "m" .* lpad.(string.(1:nrow(df)), 3, '0')

CSV.write("data/01-multicompartment-pkpd/profile-1/vp-outputs-quartile-1.csv", df)

## Plots

plots = []
for scn in unique(df.scenario)

    sdf = df[df.scenario .== scn, :]
    sort!(sdf, [:output, :t])

    p = plot(
        xlabel = "Time",
        ylabel = "Value",
        title = "Scenario: $scn",
    )

    for out in unique(sdf.output)

        odf = sdf[sdf.output .== out, :]

        q25 = Float64[]
        q50 = Float64[]
        q75 = Float64[]

        for row in eachrow(odf)
            vals = parse.(Float64, split(row."metric.values", ";"))
            push!(q25, vals[1])
            push!(q50, vals[2])
            push!(q75, vals[3])
        end

        plot!(
            p,
            odf.t,
            q50;
            seriestype = :scatter,
            label = string(out, " (median)"),
        )

        plot!(
            p,
            odf.t,
            q25;
            seriestype = :line,
            line=:dash,
            label = string(out, " (25th percentile)"),
        )

        plot!(
            p,
            odf.t,
            q75;
            seriestype = :line,
            line=:dash,
            label = string(out, " (75th percentile)"),
        )
    end

    push!(plots, p)
end

final_plot = plot(plots..., layout = (length(plots), 1), size = (800, 300 * length(plots)))

savefig(final_plot, "data/01-multicompartment-pkpd/profile-1/vp-outputs-quartile-1.png")

### quantile 10% format for DigiPopData.jl ###

levels = [0.1, 0.20, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
df = combine(
    groupby(long_df, [:scenario, :output, :t]),
    [:output, :t] => ((x,y) -> string(x[1], "_", lpad(y[1] |> Int, 3, '0'))) => "endpoint",
    :value => (x -> join(quantile(x, levels), ";")) => "metric.values",
)

df[!, "metric.levels"] .= join(levels, ";")
df[!, "metric.type"] .= "quantile"
df[!, "id"] .= "m" .* lpad.(string.(1:nrow(df)), 3, '0')

CSV.write("data/01-multicompartment-pkpd/profile-1/vp-outputs-quantile-1.csv", df)

## Plots

plots = []
for scn in unique(df.scenario)

    sdf = df[df.scenario .== scn, :]
    sort!(sdf, [:output, :t])

    p = plot(
        xlabel = "Time",
        ylabel = "Value",
        title = "Scenario: $scn",
    )

    for out in unique(sdf.output)

        odf = sdf[sdf.output .== out, :]

        q_values = Dict{Float64, Vector{Float64}}()
        for level in levels
            q_values[level] = Float64[]
        end

        for row in eachrow(odf)
            vals = parse.(Float64, split(row."metric.values", ";"))
            for (i, level) in enumerate(levels)
                push!(q_values[level], vals[i])
            end
        end

        for level in levels
            plot!(
                p,
                odf.t,
                q_values[level];
                seriestype = :line,
                label = string(out, " (", Int(level*100), "th percentile)"),
            )
        end
    end

    push!(plots, p)
end

final_plot = plot(plots..., layout = (length(plots), 1), size = (800, 300 * length(plots)))
savefig(final_plot, "data/01-multicompartment-pkpd/profile-1/vp-outputs-quantile-1.png")