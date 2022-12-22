module Readinputfile
    include("data_module.jl")
    include("readinputfile_module.jl")
    using Base.Unicode
    using Printf
    using .Readinputfile_module

    function construct(inputfilename)
        lines = nothing
        try
            lines = readlines(inputfilename)
        catch e
            @printf "%s。プログラムを終了します。\n" sprint(showerror, e)
            exit(-1)
        end

        data = Readinputfile_module.Data_module.Data_val(
            nothing,
            nothing,
            nothing,
            nothing,
            nothing)

        return Readinputfile_module.Readinputfile_variables(data, lines, 1)
    end

    errormessage(s) = let
        @printf "インプットファイルに%sの行が見つかりませんでした。\n" s
    end

    errormessage(line, s1, s2) = let
        @printf "インプットファイルの[%s]の行が正しくありません。\n" s1
        @printf "%d行目, 未知のトークン:%s\n" line s2
    end

    gettokens(rif_val, word) = let
        line = rif_val.lines[rif_val.lineindex]

        # 読み込んだ行が空、あるいはコメント行でないなら
        if !isempty(line) && line[1] != '#'
            # トークン分割
            tokens = map(line -> lowercase(line), split(line))
            w = lowercase(word)
            
            if tokens[1] != w
                errormessage(rif_val.lineindex, word, tokens[1])
                return -1, nothing
            end
            
            return 0, tokens
        else
            return 1, nothing
        end
    end

    function readdata!(default_value, rif_val, word)
        # グリッドを読み込む
        while true
            ret_val, tokens = gettokens(rif_val, word)

            if ret_val == -1
                return nothing
            elseif ret_val == 0
                rif_val.lineindex += 1
                   
                len = length(tokens)
                # 読み込んだトークンの数をはかる
                if len == 1
                    # デフォルト値を返す
                    return default_value
                elseif len == 2 
                    if tokens[2] == "default"
                        # デフォルト値を返す
                        return default_value
                    else
                        val = nothing
                        if typeof(default_value) != String
                            val = tryparse(typeof(default_value), tokens[2])
                        else
                            val = tokens[2]
                        end

                        if val !== nothing
                            return val
                        else
                            errormessage(rif_val.lineindex - 1, word, tokens[2])
                            return nothing
                        end
                    end
                else
                    str = tokens[2]

                    if str == "default" || str[1] == '#'
                        return default_value
                    elseif tokens[3][1] != '#'
                        errormessage(rif_val.lineindex - 1, word, tokens[3]);
                        return nothing
                    else
                        val = nothing
                        if typeof(default_value) != String
                            val = tryparse(typeof(default_value), tokens[2])
                        else
                            val = tokens[2]
                        end
                        
                        if val !== nothing
                            return val
                        else
                            errormessage(rif_val.lineindex - 1, word, str)
                            return nothing
                        end
                    end
                end
            end

            rif_val.lineindex += 1
        end
    end

    function readfile(rif_val)
        # グリッドの最小値を読み込む
        rif_val.data.x1 = readvalue!(Data_module.X1_DEFAULT, rif_val, "grid.x1")

        # グリッドの最大値を読み込む
        rif_val.data.x2 = readvalue!(Data_module.X2_DEFAULT, rif_val, "grid.x2")
 
        # グリッドのサイズを読み込む
        rif_val.data.grid_num = readvalue!(Data_module.GRID_NUM_DEFAULT, rif_val, "grid.num")

        # f(x1)を読み込む
        rif_val.data.f1 = readvalue!(Data_module.F1_DEFAULT, rif_val, "f1")

        # f(x2)を読み込む
        rif_val.data.f2 = readvalue!(Data_module.F2_DEFAULT, rif_val, "f2")

        return rif_val.data
    end

    function readvalue!(default_value, rif_val, word)
        val = readdata!(default_value, rif_val, word)
        if val !== nothing
            return val
        else
            throw(ErrorException("インプットファイルが異常です"))
        end
    end
end
