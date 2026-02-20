using HetaSimulator, Plots, StatsPlots
using CSV, DataFrames
using CICOBase

### Load platform and data ###

p = load_platform("model")
m = p |> models |> first |> last

# base scenario
scn0 = Scenario(m, (0., 120.); parameters = [
    :dose1 => 100.,
    :period1 => 0.,
], observables = [
    :drug_c,
    :pd_output_1,
], events_save = (false, false))
add_scenarios!(p, [:scn0 => scn0])

# load measurements
long_df = read_measurements("data/data-synthetic-known-sigma.csv", DataFrame)
add_measurements!(p, long_df)

# load optimal parameters
params_df = CSV.read("output/identifiability-intervals.csv", DataFrame)
params_opt_pairs = Symbol.(params_df.parameter) .=> params_df.optimal
params_opt = params_df.optimal

# plot fitted vs synthetic
res0 = sim(scn0; parameters = params_opt_pairs)
fig0 = plot(res0,
    legend = false, 
    grid = false,

    xlim = (-5., 125.),
    ylim = (-1., 21.),
    xlabel = nothing,
    ylabel = nothing,
    grid = false,
    markersize = 6,
    tickfontsize = 13,
    guidefontsize = 18
)
savefig(fig0, "output/1D-fitted-vs-synthetic.png")

# prediction scenario
time_points = [
    0.05, 0.1, 0.2, 0.5, 1., 2., 4., 8.,
    8.05, 8.1, 8.2, 8.5, 9., 10., 12., 16.,
    16.05, 16.1, 16.2, 16.5, 17., 18., 20., 24.,
    24.05, 24.1, 24.2, 24.5, 25., 26., 28., 32.,
    32.05, 32.1, 32.2, 32.5, 33., 34., 36., 40.,
    40.05, 40.1, 40.2, 40.5, 41., 42., 44., 48.,
    48.05, 48.1, 48.2, 48.5, 49., 50., 52., 56.,
    56.05, 56.1, 56.2, 56.5, 57., 58., 60., 64.,
    64.05, 64.1, 64.2, 64.5, 65., 66., 68., 72.,
    72.05, 72.1, 72.2, 72.5, 73., 74., 76., 80.,
    80.05, 80.1, 80.2, 80.5, 81., 82., 84., 88.,
    88.05, 88.1, 88.2, 88.5, 89., 90., 92., 96.,
    96.05, 96.1, 96.2, 96.5, 97., 98., 100., 104.,
    104.05, 104.1, 104.2, 104.5, 105., 106., 108., 112.,
    112.05, 112.1, 112.2, 112.5, 113., 114., 116., 120.,
]
scn1 = Scenario(m, (0., 120.); parameters = [
    :dose1 => 30.,
    :period1 => 8.,
], observables = [
    :drug_c,
    :pd_output_1,
], saveat = time_points, events_save = (true, false))
add_scenarios!(p, [:scn1 => scn1])

# plot predicted
res1 = sim(scn1; parameters = params_opt_pairs)
fig1 = plot(res1; 
    legend = false, 
    grid = false,
    
    xlim = (-5., 125.),
    ylim = (-1., 21.),
    xlabel = nothing,
    ylabel = nothing,
    markersize = 6,
    tickfontsize = 13,
    guidefontsize = 18
)
savefig(fig1, "output/1E-predicted.png")

### Analyze prediction bands ###

# Create estimator
est = estimator(p, params_opt_pairs;
    alg = Rodas5P(), # AutoTsit5(Rosenbrock23()) Rodas5P() FBDF() or QNDF()  CVODE_BDF()
    abstol = 1e-9,
    reltol = 1e-6
)
optimum = est(params_opt)

# create scan function
function scan_factory(time_point, output)
    scn = Scenario(m, (0., time_point); parameters = [
        :dose1 => 30.,
        :period1 => 8.,
    ], observables = [
        output,
    ], saveat = [0, time_point], events_save = (false, false))

    function scan_func(x)
        pairs = first.(params_opt_pairs) .=> x
        res = sim(scn; 
            parameters = pairs,     
            alg = Rodas5P(),
            abstol = 1e-9,
            reltol = 1e-6
        )
        res_df = res |> DataFrame
        target = res_df[2, output]
        return target
    end
end

prediction_bands_df = DataFrame(
    time_point = Float64[],
    lower_bound = Union{Nothing, Float64}[],
    lower_status = Symbol[],
    optimal = Union{Nothing, Float64}[],
    upper_bound = Union{Nothing, Float64}[],
    upper_status = Symbol[],
    output = Symbol[],
)
for out in [:drug_c, :pd_output_1]
    #out = :pd_output_1
    println("Calculating prediction bands for output: ", out, "\n")

    for t_i in time_points
        # t_i = 0.05
        println("\tCalculating interval for time point: ", t_i, "\n")

        scan_fun_i = scan_factory(t_i, out)

        # calc band
        interval_i = get_interval(
            params_opt, # theta_init
            scan_fun_i, # scan_func
            est, # loss_func
            :CICO_ONE_PASS, # method

            loss_crit = optimum + 3.84,
            scan_bounds = (1e-5, 30.0),
            scale = fill(:log, length(params_opt))
        )

        left = interval_i.result[1]
        right = interval_i.result[2]

        # claculate optimal
        optimal = scan_fun_i(params_opt)

        # store results
        push!(prediction_bands_df, (
            time_point = t_i,
            lower_bound = left.value,
            lower_status = left.status,
            optimal = optimal,
            upper_bound = right.value,
            upper_status = right.status,
            output = out,
        ))
    end
end

#save
CSV.write("output/prediction-bands.csv", prediction_bands_df; transform=(col, val) -> something(val, missing))

### Analyze prediction bands 2 ###
time_points_2 = [
    0.05, 0.1, 0.2, 0.5, 1., 2., 4., 8., 12., 18., 24.,
    32., 40., 48., 56., 64., 72., 80., 88., 96., 104., 112., 120.,
]

# create scan function
function scan_factory_2(time_point, output)
    scn = Scenario(m, (0., time_point); parameters = [
        :dose1 => 100.,
        :period1 => 0.,
    ], observables = [
        output,
    ], saveat = [0, time_point], events_save = (false, false))

    function scan_func(x)
        pairs = first.(params_opt_pairs) .=> x
        res = sim(scn; 
            parameters = pairs,     
            alg = Rodas5P(),
            abstol = 1e-9,
            reltol = 1e-6
        )
        res_df = res |> DataFrame
        target = res_df[2, output]
        return target
    end
end

prediction_bands_df_2 = DataFrame(
    time_point = Float64[],
    lower_bound = Union{Nothing, Float64}[],
    lower_status = Symbol[],
    optimal = Union{Nothing, Float64}[],
    upper_bound = Union{Nothing, Float64}[],
    upper_status = Symbol[],
    output = Symbol[],
)
for out in [:drug_c, :pd_output_1]
    #out = :pd_output_1
    println("Calculating prediction bands for output: ", out, "\n")

    for t_i in time_points_2
        # t_i = 0.05
        println("\tCalculating interval for time point: ", t_i, "\n")

        scan_fun_i = scan_factory_2(t_i, out)

        # calc band
        interval_i = get_interval(
            params_opt, # theta_init
            scan_fun_i, # scan_func
            est, # loss_func
            :CICO_ONE_PASS, # method

            loss_crit = optimum + 3.84,
            scan_bounds = (1e-5, 30.0),
            scale = fill(:log, length(params_opt))
        )

        left = interval_i.result[1]
        right = interval_i.result[2]

        # claculate optimal
        optimal = scan_fun_i(params_opt)

        # store results
        push!(prediction_bands_df_2, (
            time_point = t_i,
            lower_bound = left.value,
            lower_status = left.status,
            optimal = optimal,
            upper_bound = right.value,
            upper_status = right.status,
            output = out,
        ))
    end
end

#save
CSV.write("output/prediction-bands-2.csv", prediction_bands_df_2; transform=(col, val) -> something(val, missing))