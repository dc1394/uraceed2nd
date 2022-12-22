module Saveresult
    using Printf
    
    function saveresult(data, xarray, yarray)
        open("result.csv", "w" ) do fp

            for i = 1:(data.grid_num + 1)
                write(fp, @sprintf("%.15f, %.15f\n", xarray[i], yarray[i]))
            end
        end
    end
end