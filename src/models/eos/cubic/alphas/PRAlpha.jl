abstract type PRAlphaModel <: AlphaModel end

struct PRAlphaParam <: EoSParam
    acentricfactor::SingleParam{Float64}
end

@newmodelsimple PRAlpha PRAlphaModel PRAlphaParam

export PRAlpha
function PRAlpha(components::Vector{String}; userlocations::Vector{String}=String[], verbose::Bool=false)
    params = getparams(components, ["properties/critical.csv"]; userlocations=userlocations, verbose=verbose)
    acentricfactor = SingleParam(params["w"],"acentric factor")
    packagedparams = PRAlphaParam(acentricfactor)
    model = PRAlpha(packagedparams, verbose=verbose)
    return model
end

function α_function(model::CubicModel,V,T,z,alpha_model::PRAlphaModel)
    Tc = model.params.Tc.values
    ω  = alpha_model.params.acentricfactor.values
    α = @. (1+(0.37464+1.54226*ω-0.26992*ω^2)*(1-√(T/Tc)))^2
    return α
end