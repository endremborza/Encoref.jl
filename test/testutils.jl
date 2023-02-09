
function generate_dfpair(n, str_cols = 2, float_cols = 5)
    DfPair([
        DataFrame(union(
            Dict("scol_$i" => [randstring(rand(4:20)) for _ = 1:n] for i = 1:str_cols),
            Dict("fcol_$i" => rand(n) for i = 1:float_cols),
        )) for i = 1:2
    ]...)
end

function load_result(dir::String)
    res_dir = joinpath(dir, "result")
    Dict(split(resf, ".")[1] => ParquetFiles.load(joinpath(res_dir, resf)) |> DataFrame |> df -> hcat(df.i1, df.i2) 
    for resf in readdir(res_dir))
end