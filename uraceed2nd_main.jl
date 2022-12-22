include("comlineoption.jl")
include("readinputfile.jl")
include("solve_ode.jl")
include("saveresult.jl")
using .Comlineoption
using .Readinputfile
using .Saveresult

function main(args)
    opt = Comlineoption.construct(args)
    rif_val = Readinputfile.construct(opt.inpname)
    data = Readinputfile.readfile(rif_val)

    solve_tf_param, solve_tf_val = Solve_ODE.construct(data)

    xarray, yarray = Solve_ODE.solvetf!(solve_tf_param, solve_tf_val)
    Saveresult.saveresult(data, xarray, yarray)
end

@time main(ARGS)