### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ a68f6637-48ab-4a98-8ec3-3d37edaf2f6f
begin
    import Pkg
    # activate the shared project environment
    Pkg.activate(".")
	using CSV, DataFrames, Plots, Polynomials, StatsBase, LsqFit
end

# ╔═╡ 748b6800-f66f-11ee-23cf-01a58e5a83a2
html"""
<style>
	@media screen {
		main {
			margin: 0 auto;
			max-width: 2000px;
    		padding-left: max(283px, 10%);
    		padding-right: max(383px, 10%); 
            # 383px to accomodate TableOfContents(aside=true)
		}
	}
</style>
"""

# ╔═╡ 042668e1-0102-4af0-83d8-b7ae788f0a9d
plotly()

# ╔═╡ da418bb5-1c77-4d4a-b1e0-874f850d2caf
#correct, extract, and plot data
function datahandle(all_cases, zero_cases, m_conc, excl, df_cal)
	plt = plot()
	max=zeros(length(all_cases)-length(excl))
	avg=zeros(length(all_cases)-length(excl))
	conc=zeros(length(all_cases)-length(excl))
	j=0
	for (i, x) in enumerate(all_cases)
		if i ∉ excl
			j+=1
			id = parse(Int, string(all_cases[i])[2])# (i-1)%4+1
			df_cal[!, x] .-= df_cal[!, zero_cases[id]]
			max[j] = maximum(df_cal[!, x])
			avg[j] = maximum(df_cal[50:54, x])
			conc[j] = m_conc[i]
			plot!(df_cal.wl, df_cal[!, x], label=string(x))
			
		end
	end
	return plt, conc, max, avg
end

# ╔═╡ ee8f449d-77e6-457c-90a2-402a4a4f5f16
function fitpol(order, abs, conc)
	plt = plot()
	@. model6(x,p) = p[1] + p[2]*x + p[3]*x^2 + p[4]*x^3 + p[5]*x^4 + p[6]*x^5 + p[7]*x^6
	@. model5(x,p) = p[1] + p[2]*x + p[3]*x^2 + p[4]*x^3 + p[5]*x^4 + p[6]*x^5
	@. model4(x,p) = p[1] + p[2]*x + p[3]*x^2 + p[4]*x^3 + p[5]*x^4
	@. model3(x,p) = p[1] + p[2]*x + p[3]*x^2 + p[4]*x^3
	model = if order == 4
		model4
	elseif order == 5
		model5
	elseif order == 6
		model6
	else
		model3
	end
	fitted = Polynomials.fit(ArnoldiFit, abs, conc, order)
	p0 = fitted.coeffs
	lsq = LsqFit.curve_fit(model, abs, conc, p0)
	plsq = coef(lsq)
	scatter!(abs, conc, yaxis=(scale=:log10), label="meas")
	x_range = range(minimum(abs), maximum(abs), 20)
	plot!(x_range, fitted.(x_range), legend=:topleft, label="fit")
	plot!(x_range, model(x_range, plsq), legend=:topleft, label="lsq")
	error = rmsd(conc, model(abs, plsq); normalize=true)
	return plt, plsq, error, model
end

# ╔═╡ 40d20122-8196-4e4d-a902-f8811c42bdb0
# get data
begin
	df_cal = DataFrame(CSV.File("20240406_cal2", delim=",", header=1, transpose=true))
	df_cal = df_cal[1:300, :]
	wl = df_cal[:,1]
	m_conc = [80620, 53747, 26873, 8958, 40310, 26873, 20155, 13437, 22700, 15133, 11350, 7567, 11350, 7567, 5675, 3783, 5675, 3783, 2838, 1892]
	all_cases = [:A1, :A2, :A3, :A4, :B1, :B2, :B3, :B4, :C1, :C2, :C3, :C4, :D1, :D2, :D3, :D4, :E1, :E2, :E3, :E4]
	zero_cases = [:Z1, :Z2, :Z3, :Z4]
	rename!(df_cal, names(df_cal) .=> vcat([:wl], all_cases, zero_cases))

	plt, conc, abs, avg = datahandle(all_cases, zero_cases, m_conc, Set([3,4]), df_cal)
	plt2, plsq, error, model = fitpol(6, abs, conc)
	plot(plt, plt2;  size = (1200, 500), layout=(1,2), legend=:outerright)
end

# ╔═╡ 291da86b-8bb2-4d6f-b7d6-b452f31c9f44
# get data
begin
	df_calB = DataFrame(CSV.File("20240408_cal2", delim=",", header=1, transpose=true))
	df_calB = df_calB[1:300, :]
	wlB = df_calB[:,1]
	m_concB = [81100, 54067, 27033, 9011, 40310, 26873, 20155, 13437, 22700, 13517, 11350, 7567, 11350, 7567, 5675, 3783]
	all_casesB = [:A1, :A2, :A3, :A4, :B1, :B2, :B3, :B4, :C1, :C2, :C3, :C4, :D1, :D2, :D3, :D4]
	#zero_cases = [:Z1, :Z2, :Z3, :Z4]
	rename!(df_calB, names(df_calB) .=> vcat([:wl], all_casesB, zero_cases))

	pltB, concB, absB, avgB = datahandle(all_casesB, zero_cases, m_concB, Set([3,4]), df_calB)
	plt2B, plsqB, errorB, modelB = fitpol(5, absB, concB)
	plot(pltB, plt2B;  size = (1200, 500), layout=(1,2), legend=:outerright)
end

# ╔═╡ 56d6c8f3-45d1-4305-b92e-706b11d71053
begin
	abs_range = range(0.2, 1.7, 50)
	cat_no = model(abs_range, plsq)
	cat_w = modelB(abs_range, plsqB)
	plot(abs_range, cat_no, label="nocat")
	plot!(abs_range, cat_w, yaxis=:log, label="with cat", legend=:topleft)
end

# ╔═╡ cdb4b411-6e1c-48b5-b147-dc13010b8be0
begin
	ratio = log10.(cat_w) ./ log10.(cat_no)
	plot(ratio)
end

# ╔═╡ 1ae8d723-9d27-4cb3-afbd-754df2c840cf
"$(mean(ratio))  $(std(ratio))"

# ╔═╡ Cell order:
# ╟─748b6800-f66f-11ee-23cf-01a58e5a83a2
# ╠═a68f6637-48ab-4a98-8ec3-3d37edaf2f6f
# ╠═042668e1-0102-4af0-83d8-b7ae788f0a9d
# ╟─da418bb5-1c77-4d4a-b1e0-874f850d2caf
# ╠═ee8f449d-77e6-457c-90a2-402a4a4f5f16
# ╠═40d20122-8196-4e4d-a902-f8811c42bdb0
# ╠═291da86b-8bb2-4d6f-b7d6-b452f31c9f44
# ╠═56d6c8f3-45d1-4305-b92e-706b11d71053
# ╠═cdb4b411-6e1c-48b5-b147-dc13010b8be0
# ╠═1ae8d723-9d27-4cb3-afbd-754df2c840cf
