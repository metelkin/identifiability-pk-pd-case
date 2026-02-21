using Plots

function hill(drug_t, Emin_1, Emax_1, EC50_1, h_1)
    pd_output_1 = Emin_1 + Emax_1 * drug_t^h_1 / (drug_t^h_1 + EC50_1^h_1)
end

drug_t_seq = collect(-4.:0.1:4.) .|> x -> 10.0^x 
function hell_seq(Emin_1, Emax_1, EC50_1, h_1)
    hill.( drug_t_seq, Emin_1, Emax_1, EC50_1, h_1)
end

x = drug_t_seq

fig = plot(
    xscale = :log10,
    xlim = (1e-3, 1e4),
    ylim = (0, 20),
    legend = false,
    grid = false,

    markersize = 10,
    #framestyle = :none
    #xticks = nothing,
    #yticks = nothing
    formatter = _ -> ""
)

y0 = hell_seq(5.2, 10.1, 1.2, 0.8)
plot!(fig, x, y0; linewidth = 4)

y1 = hell_seq(4.8, 10.5, 10.8, 1.4)
plot!(fig, x, y1; linewidth = 4)

y2 = hell_seq(4.3, 16.2, 100., 0.8)
plot!(fig, x, y2; linewidth = 4)

# experimental points with noise
drug_t_exp = [-2.5, -1.5, -0.5, 2., 3.] .|> x -> 10.0^x
y_exp = [5., 4.5, 6., 14., 16.5]
y_noise = [1., 1.4, 2., 2., 2.]

scatter!(fig, drug_t_exp, y_exp;
    yerror = y_noise,
    markersize = 6, 
    color = :black
)

savefig("output/0-hill-curve.png")
