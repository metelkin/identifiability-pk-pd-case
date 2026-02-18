using HetaSimulator, Plots, StatsPlots
using CSV, DataFrames
using CICOBase

p = load_platform("model")
m = p |> models |> first |> last

scn0 = Scenario(m, (0., 120.); parameters = [
    :dose1 => 100.,
    :period1 => 0.,
], observables = [
    :drug_c,
    :pd_output_1,
], events_save = (false, false))
res0 = sim(scn0)
add_scenarios!(p, [:scn0=>scn0])

long_df = read_measurements("data/data-synthetic-known-sigma.csv", DataFrame)

# add data to platform
add_measurements!(p, long_df)
fig0 = plot(res0, legend = false, grid = false)
savefig(fig0, "output/true-vs-synthetic.png")

# loss function
to_fit = [
    # PK
    :Vc_0 => 5.5,
    :kel => 3e-1,
    :kdist_p => 7e-1,
    :kdist_t => 1e-2,
    # PD
    :EC50_1 => 0.8,
    #:h_1 => 1.2,
    :Emin_1 => 5.,
    :Emax_1 => 10.,
    # params
    #:sigma1 => 0.1,
    #:sigma2 => 0.1,
]
res_optim = HetaSimulator.fit(p, to_fit) # 17.50
res_optim = HetaSimulator.fit(p, optim(res_optim)) # 17.405
params_optim = optim(res_optim)

res0 = sim(p; parameters = params_optim) 
fig0 = plot(res0, legend = false, grid = false)
savefig(fig0, "output/1D-fitted-vs-synthetic.png")
save_as_heta("data/fitted-params.heta", res_optim)

est = estimator(p, params_optim;
    alg = Rodas5P(), # AutoTsit5(Rosenbrock23()) Rodas5P() FBDF() or QNDF()  CVODE_BDF()
    abstol = 1e-9,
    reltol = 1e-6
)
values_optim = params_optim .|> last
est(values_optim)

# identifiability analysis
intervals = []
figures = []
for (i, p) in enumerate(params_optim[1:7])
    println("Profiling parameter: ", p)
    res_i = get_interval(
        values_optim,
        i,
        est,
        :CICO_ONE_PASS,
        loss_crit = est(values_optim) + 3.84, # 95% CI for 1 parameter
        scan_bounds = (1e-3, 1e3),
        scale = fill(:log, length(values_optim))
    )
    push!(intervals, res_i)

    plot(res_i)
    push!(figures, plot(res_i))
end

intervals_df = DataFrame(
    parameter = [p[1] for p in params_optim],
    lower_bound = [x.result[1].value for x in intervals],
    optimal = values_optim,
    upper_bound = [x.result[2].value for x in intervals],
    status_lower = [x.result[1].status for x in intervals],
    status_upper = [x.result[2].status for x in intervals],
)
intervals_df.true_value = [p[2] for p in to_fit]

CSV.write("output/identifiability-intervals.csv", intervals_df; transform=(col, val) -> something(val, missing))

