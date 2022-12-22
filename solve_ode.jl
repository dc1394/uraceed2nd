module Solve_ODE
    include("readinputfile.jl")
    include("solve_ode_module.jl")
    using LinearAlgebra
    using Match
    using .Solve_ODE_module

    function boundary_conditions!(solve_ode_val, solve_ode_param)
        a = solve_ode_param.F0
        solve_ode_val.vec_b_glo[1] = a
        solve_ode_val.vec_b_glo[2] -= a * solve_ode_val.tmp[1]
        
        b = solve_ode_param.F1
        solve_ode_val.vec_b_glo[solve_ode_param.NODE_TOTAL] = b
        solve_ode_val.vec_b_glo[solve_ode_param.NODE_TOTAL - 1] -= b * solve_ode_val.tmp[2]
    end

    function construct(data)
        solve_ode_param = Solve_ODE_module.Solve_ODE_param(
            data.grid_num,
            data.grid_num + 1,
            data.x1,
            data.x2,
            data.f1,
            data.f2)

        solve_ode_val = Solve_ODE_module.Solve_ODE_variables(
            Array{Float64}(undef, solve_ode_param.ELE_TOTAL),
            SymTridiagonal(Array{Float64}(undef, solve_ode_param.NODE_TOTAL), Array{Float64}(undef, solve_ode_param.NODE_TOTAL - 1)),
            Array{Int64, 2}(undef, solve_ode_param.ELE_TOTAL, 2),
            Array{Float64, 2}(undef, solve_ode_param.ELE_TOTAL, 2),
            Array{Float64}(undef, solve_ode_param.NODE_TOTAL),
            Array{Float64}(undef, 2),
            Array{Float64}(undef, solve_ode_param.NODE_TOTAL),
            Array{Float64}(undef, solve_ode_param.ELE_TOTAL, 2),
            Array{Float64}(undef, solve_ode_param.NODE_TOTAL))

        make_data!(solve_ode_param, solve_ode_val)
        make_global_matrix!(solve_ode_param, solve_ode_val)

        return solve_ode_param, solve_ode_val
    end
    
    function make_data!(solve_ode_param, solve_ode_val)
        @inbounds for i = 0:solve_ode_param.ELE_TOTAL
            solve_ode_val.node_x_glo[i + 1] = (solve_ode_param.X2 - solve_ode_param.X1) / convert(Float64, solve_ode_param.ELE_TOTAL) * convert(Float64, i)
        end

        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            solve_ode_val.node_num_seg[e, 1] = e
            solve_ode_val.node_num_seg[e, 2] = e + 1
        end
            
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            for i = 1:2
                solve_ode_val.node_x_ele[e, i] = solve_ode_val.node_x_glo[solve_ode_val.node_num_seg[e, i]]
            end
        end

        # 各線分要素の長さを計算
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            solve_ode_val.length[e] = abs(solve_ode_val.node_x_ele[e, 2] - solve_ode_val.node_x_ele[e, 1])
        end
    end

    function make_element_vector!(solve_ode_param, solve_ode_val)
        # Local節点ベクトルの各成分を計算
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            for i = 1:2
                solve_ode_val.vec_b_ele[e, i] =
                    @match i begin
                        1 => - solve_ode_val.length[e] / 2.0
                        2 => - solve_ode_val.length[e] / 2.0
                        _ => 0.0
                    end
            end
        end
    end

    function make_global_matrix!(solve_ode_param, solve_ode_val)
        # 要素行列
        mat_A_ele = Array{Float64}(undef, solve_ode_param.ELE_TOTAL, 2, 2)

        # 要素行列の各成分を計算
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            for i = 1:2
                for j = 1:2
                    mat_A_ele[e, i, j] = (-1) ^ i * (-1) ^ j / solve_ode_val.length[e]
                end
            end
        end

        tmp_dv = zeros(solve_ode_param.NODE_TOTAL)
        tmp_ev = zeros(solve_ode_param.NODE_TOTAL - 1)

        # 全体行列を生成
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            for i = 1:2
                for j = 1:2
                    if solve_ode_val.node_num_seg[e, i] == solve_ode_val.node_num_seg[e, j]
                        tmp_dv[solve_ode_val.node_num_seg[e, i]] += mat_A_ele[e, i, j]
                    elseif solve_ode_val.node_num_seg[e, i] + 1 == solve_ode_val.node_num_seg[e, j]
                        tmp_ev[solve_ode_val.node_num_seg[e, i]] += mat_A_ele[e, i, j]
                    end
                end
            end
        end

        # 全体ベクトルの境界条件処理のために保管しておく
        solve_ode_val.tmp[1] = tmp_ev[1] 
        solve_ode_val.tmp[2] = tmp_ev[solve_ode_param.NODE_TOTAL - 1]

        # 全体行列の境界条件処理
        tmp_dv[1] = 1.0
        tmp_ev[1] = 0.0
        tmp_dv[solve_ode_param.NODE_TOTAL] = 1.0
        tmp_ev[solve_ode_param.NODE_TOTAL - 1] = 0.0

        solve_ode_val.mat_A_glo = SymTridiagonal(tmp_dv, tmp_ev)
    end

    function make_global_vector!(solve_ode_param, solve_ode_val)
        solve_ode_val.vec_b_glo = zeros(solve_ode_param.NODE_TOTAL)

        # 全体行列と全体ベクトルを生成
        @inbounds for e = 1:solve_ode_param.ELE_TOTAL
            for i = 1:2
                solve_ode_val.vec_b_glo[solve_ode_val.node_num_seg[e, i]] += solve_ode_val.vec_b_ele[e, i]
            end
        end
    end
    
    function solvetf!(solve_ode_param, solve_ode_val)
        # Local節点ベクトルを生成
        make_element_vector!(solve_ode_param, solve_ode_val)
                
        # 全体ベクトルを生成
        make_global_vector!(solve_ode_param, solve_ode_val)

        # 境界条件処理
        boundary_conditions!(solve_ode_val, solve_ode_param)

        # 連立方程式を解く
        solve_ode_val.ug = solve_ode_val.mat_A_glo \ solve_ode_val.vec_b_glo

        return solve_ode_val.node_x_glo, solve_ode_val.ug
    end
end