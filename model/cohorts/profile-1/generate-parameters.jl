using CSV, DataFrames
using JSON3, Distributions

# load from file and generate
json = JSON3.read("models/01-multicompartment-pkpd/cohorts/profile-1/variability.json")
size = json["size"]

parameters_df = DataFrame()
for rule in json["parameters"]
    if rule["distribution"] == "lognormal"
        mean, std = rule["parameters"]
        name = rule["name"]
        parameters_df[!, name] = rand(Normal(log(mean), std), size) .|> exp
    else
        error("Unsupported distribution: $(rule["distribution"])")
    end
end

CSV.write("data/01-multicompartment-pkpd/profile-1/vp-parameters-1.csv", parameters_df)
