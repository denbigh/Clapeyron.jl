using NLopt,DiffResults,ForwardDiff,LinearAlgebra

function Volume(EoS,model,z,p,T,phase="unknown")
    N = length(p)
    pai = 3.14159265359
    N_A = 6.02214086e23

    ub = [Inf]
    lb = [log10(pai/6*N_A*segments[1]*sigmas[1]^3/1)]

    if phase == "unknown" || phase == "liquid"
        x0 = [log10(pai/6*N_A*segments[1]*sigmas[1]^3/0.9)]
    elseif phase == "vapour"
        x0 = [log10(pai/6*N_A*segments[1]*sigmas[1]^3/1e-3)]
    end

    Vol = []
    if phase == "unknown"
        for i in 1:N
            f(v) = EoS(z[i,:],10^v[1],T[i])+10^v[1]*p[i]/T[i]/8.314
            (f_best,v_best) = Tunneling(f,lb,ub,x0)
            append!(Vol,10^v_best[1])
        end
    else
        opt_min = NLopt.Opt(:LD_MMA, length(ub))
        opt_min.lower_bounds = lb
        opt_min.upper_bounds = ub
        opt_min.xtol_rel = 1e-8
        obj_f0 = x -> f(x)
        obj_f = (x,g) -> NLopt_obj(obj_f0,x,g)
        opt_min.min_objective =  obj_f
        for i in 1:N
            f(v) = EoS(z[i,:],10^v[1],T[i])+10^v[1]*p[i]/T[i]/8.314
            (f_min,v_min) = NLopt.optimize(opt_min, x0)
            append!(Vol,10^v_min[1])
        end
    end
    return Vol
end

function Tunneling(f,lb,ub,x0)
    N = length(ub)
    # Relevant configuration
    tolf=1e-8

    # Minimisation phase
    opt_min = NLopt.Opt(:LD_MMA, length(ub))
    opt_min.lower_bounds = lb
    opt_min.upper_bounds = ub
    opt_min.xtol_rel = 1e-8

    obj_f0 = x -> f(x)
    obj_f = (x,g) -> NLopt_obj(obj_f0,x,g)
    opt_min.min_objective =  obj_f

    (min_f,min_x,status) = NLopt.optimize(opt_min, x0)

    best_f = min_f
    opt_x  = []
    best_x = min_x
    append!(opt_x,[min_x])

    # Tunneling phase
    opt_tun = NLopt.Opt(:LD_MMA, length(ub))
    opt_tun.lower_bounds = lb
    opt_tun.upper_bounds = ub
    opt_tun.xtol_rel = 1e-8
    opt_tun.stopval = -1e-6

    for i in 1:10*N
        T0 = x -> (f(x)-f_best)*prod(exp(1e-2/sqrt(sum((x[i]-x_opt[j][i])^2 for i in 1:N))) for j in 1:k)
        T  = (x,g) -> NLopt_obj(T0,x,g)
        opt_tun.min_objective =  T

        r  = 2.0.*rand(Float64,(N)).-1.0
        ϵ1 = 2*(tolf)^(1/5)*(1+norm(best_x,2))
        x0 = r/norm(r,2).*ϵ1+best_x
        x0 = ub.*(x0.>=ub)+lb.*(x0.<=lb)+x0.*(ub.>x0.>lb)

        # Tunneling
        (new_f,new_x,status) = NLopt.optimize(opt_tun, x0)
        if status != :FORCED_STOP
            println(i)
            break
        end
        # Minimisation
        (min_f,min_x,status) = NLopt.optimize(opt_min, new_x)
        if min_f<best_f
            best_f = min_f
            best_x = min_x
            opt_x  = []
            append!(opt_x,[min_x])
        else
            append!(opt_x,[min_x])
        end

    end
    return (best_f,best_x)
end

function NLopt_obj(f,x,g)
        if length(g) > 0
            df = DiffResults.GradientResult(x)
            df = ForwardDiff.gradient!(df,f,x)
            g .= DiffResults.gradient(df)
            return DiffResults.value(df)
        else
            return f(x)
        end
end
