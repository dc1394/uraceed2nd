module Data_module
    const F1_DEFAULT = 0.0

    const F2_DEFAULT = 1.0

    const GRID_NUM_DEFAULT = 10
    
    const X1_DEFAULT = 0.0

    const X2_DEFAULT = 1.0

    mutable struct Data_val
        f1::Union{Int32, Nothing}
        f2::Union{Int32, Nothing}
        grid_num::Union{Int32, Nothing}
        x1::Union{Float64, Nothing}
        x2::Union{Float64, Nothing}
    end
end