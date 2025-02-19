abstract type MTAlphaModel <: AlphaModel end

struct MTAlphaParam <: EoSParam
    acentricfactor::SingleParam{Float64}
end

@newmodelsimple MTAlpha MTAlphaModel MTAlphaParam

export MTAlpha
function MTAlpha(components::Vector{String}; userlocations::Vector{String}=String[], verbose::Bool=false)
    params = getparams(components, ["properties/critical.csv"]; userlocations=userlocations, verbose=verbose)
    acentricfactor = SingleParam(params["w"],"acentric factor")
    packagedparams = MTAlphaParam(acentricfactor)
    model = MTAlpha(packagedparams, verbose=verbose)
    return model
end

function α_function(model::CubicModel,V,T,z,alpha_model::MTAlphaModel)
    Tc = model.params.Tc.values
    Tr = @. T/Tc
    ω  = alpha_model.params.acentricfactor.values
    m  = @. 0.384401+1.52276*ω-0.213808*ω^2+0.034616*ω^3-0.001976*ω^4
    return @. (1+m*(1-√(Tr)))^2
end