Base.broadcastable(model::EoSModel) = Ref(model)

"""
    eos(model::EoSModel, V, T, z=SA[1.0])

basic Clapeyron function, returns the total Helmholtz free energy.

# Inputs:
- `model::EoSModel` Thermodynamic model to evaluate
- `V` Total volume, in [m³]
- `T` Temperature, in [K]
- `z` mole amounts, in [mol], by default is `@SVector [1.0]`

# Outputs:

- Total Helmholtz free energy, in [J]

by default, it calls `R̄*T*∑(z)*(a_ideal(ideal_model,V,T,z) + a_res(model,V,T,z))` where `ideal_model == idealmodel(model)`, where `a_res` is the reduced residual Helmholtz energy and `a_ideal` is the reduced ideal Helmholtz energy.
You can mix and match ideal models if you provide:
- `idealmodel(model)`: extracts the ideal model from your Thermodynamic model
- `a_res(model,V,T,z)`: residual reduced Helmholtz free energy

"""
function eos(model::EoSModel, V, T, z=SA[1.0])
    return N_A*k_B*∑(z)*T * (a_ideal(idealmodel(model),V,T,z)+a_res(model,V,T,z))
end
"""
    idealmodel(model::EoSModel)
    
retrieves the ideal model from the input's model.

# Examples:

```julia-repl
julia> pr = PR(["water"],idealmodel=IAPWS95Ideal)   
PR{IAPWS95Ideal} with 1 component:
 "water"
Contains parameters: a, b, acentricfactor, Tc, Mw   
julia> Clapeyron.idealmodel(pr)
IAPWS95Ideal()
```

"""
idealmodel(model::EoSModel) = model.idealmodel

function eos(model::IdealModel, V, T, z=SA[1.0])
    negative_vt(V,T) && return nan_num(V,T,z)
    return N_A*k_B*sum(z)*T * a_ideal(model,V,T,z)
end


"""
    eos_res(model::EoSModel, V, T, z=SA[1.0])

basic Clapeyron function, returns the residual Helmholtz free energy.

# Inputs:
- `model::EoSModel` Thermodynamic model to evaluate
- `V` Total volume, in [m³]
- `T` Temperature, in [K]
- `z` mole amounts, in [mol], by default is `@SVector [1.0]`

# Outputs:

- Residual Helmholtz free energy, in [J]

by default, it calls `R̄*T*∑(z)*(a_res(model,V,T,z))` where `a_res` is the reduced residual Helmholtz energy.
"""
function eos_res(model::EoSModel, V, T, z=SA[1.0])
    return N_A*k_B*∑(z)*T * (a_res(model,V,T,z))
end

# function eos(model::CubicModel, V, T, z)
#     return N_A*k_B*sum(z)*T * a_tot(model,V,T,z)
# end



"""
    component_names(model)::Vector{tring}

returns a vector of strings of each component.
"""
component_names(model) = model.components