using Encoref
using Test, ParquetFiles, DataFrames


function load_result(dir::String)
    res_dir = joinpath(dir, "result")
    Dict(
        split(resf, ".")[1] => load(joinpath(res_dir, resf)) |> DataFrame |> df -> hcat(df.i1, df.i2) 
        for resf in readdir(res_dir)
    )
end

max_level = 0

test_dirs = ["test_data/test_sys_$i" for i in 0:0]


@testset "Encoref.jl" begin
    @test 1 == 1
end

@testset "e2e" begin

    for test_dir in test_dirs
        true_res = load_result(test_dir)
        @test true_res == Dict(k=>sortslices(v, dims=1) for (k,v) in coref(CorefSystem(test_dir)))
    end

end