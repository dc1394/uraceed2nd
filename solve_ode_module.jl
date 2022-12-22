module Solve_ODE_module
    using LinearAlgebra

    struct Solve_ODE_param
        ELE_TOTAL::Int64
        NODE_TOTAL::Int64
        X1::Float64
        X2::Float64
        F0::Float64
        F1::Float64
    end

    mutable struct Solve_ODE_variables
        length::Array{Float64, 1}
        mat_A_glo::SymTridiagonal{Float64,Array{Float64,1}}
        node_num_seg::Array{Int64, 2}
        node_x_ele::Array{Float64, 2}
        node_x_glo::Array{Float64, 1}
        tmp::Array{Float64, 1}
        ug::Array{Float64, 1}
        vec_b_ele::Array{Float64, 2}
        vec_b_glo::Array{Float64, 1}
    end
end