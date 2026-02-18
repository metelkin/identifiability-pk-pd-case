using HetaSimulator
using Plots, CSV, DataFrames

p = load_platform("models/01-multicompartment-pkpd")
m = p.models[:nameless]

## Default scenario
res = Scenario(m, (0., 120.)) |> sim
plot(res; vars = [:drug_c, :pd_output_1])

## pool-1 scenarios
scn_csv = read_scenarios("models/01-multicompartment-pkpd/scenarios/pool-1.csv")
add_scenarios!(p, scn_csv)

res = sim(p)
plot(res)
res_df = DataFrame(res)
#CSV.write("1.csv", res_df)
