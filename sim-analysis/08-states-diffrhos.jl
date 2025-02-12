using Pkg
Pkg.activate("../sim-scripts/Poodl")

using Revise
import Poodl
const  pdl  = Poodl


using Plots
gr(legend = false)
Plots.scalefontsizes(1.3)
using LaTeXStrings

using Base: product
using Lazy: lazymap, @lazy




#=

testar σ 0.02 0.04 0.06  e 0.1

testar n_issues 1,5

testar p★, p★★, p★★★

=#


σs = [0.02,0.06,0.1]
n_issues = [1,5,10]
pstars = [pdl.calculatep★, pdl.calculatep★★, pdl.calculatep★★★]


initialrho = 0.05

pintran = 0.0


# Array{Float}, Array{Int}, Array{Function} -> Array{pdl.Param}
function poodlparamsgen(σs, n_issues, pstars, initialrho, pintran)

    foo  = lazymap(x-> (σ = x[1], n_issues = x[2], p★calculator = x[3]),
                     (@lazy product(σs, n_issues, pstars)))

    bar = []

    for t in foo
        newrho = initialrho * sqrt(t.n_issues)
        push!(bar, newrho)
    end
    params  = zip(foo, bar)  |> z -> map(x-> (σ = x[1].σ,
                                           n_issues =  x[1].n_issues,
                                           p★calculator = x[1].p★calculator,
                                           ρ = x[2]), z)

    lazymap(y-> pdl.PoodlParam(n_issues = y.n_issues,
                          σ = y.σ,
                          size_nw = 500,
                          time = 500_000,
                          p = 0.9,
                          ρ = y.ρ,
                          propintransigents = pintran,
                          p★calculator = y.p★calculator), params)
end


function pstartitle(p::Function)
    if p == pdl.calculatep★
        "p*"
    elseif p == pdl.calculatep★★
        "p**"
    else
        "p***"
    end
end


function runandsaveplot(pa)
    simresult = pdl.statesmatrix(pa)
    fig = plot(show = false, xlabel = "iterations",
               ylabel = "mean opinion values",
               title = (pstartitle(pa.p★calculator) *
                        "  ; n = $(pa.n_issues) ; sigma = $(pa.σ)"),
               dpi = 200)


    pdl.Meter.@showprogress 1 "Plotting " for i in 1:pa.size_nw
        plot!(fig, simresult[:,i])
    end

    if pa.propintransigents == 0
        png("img/statearray-stuff/$(pa.p★calculator)n$(pa.n_issues)-rho$(pa.ρ)-sigma$(pa.σ)-$(pa.propintransigents)intrans")
        
    else
        png("img/statearray-stuff/$(pa.p★calculator)n$(pa.n_issues)-rho$(pa.ρ)-sigma$(pa.σ)-$(pa.intranpositions)$(pa.propintransigents)intrans")
  
    end
    fig = 0
    simresult = 0      
end

function sweepandplot(params)
    for (index,value) in enumerate(params)
        runandsaveplot(value)
        println("plot $(index) saved")
    end
end


params = poodlparamsgen(σs, n_issues, pstars, initialrho, pintran)


pdl.statesmatrix(pdl.PoodlParam())


sweepandplot(params)


