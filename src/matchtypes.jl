using DataFrames, JSON
import ParquetFiles

struct DfPair
    df1::DataFrame
    df2::DataFrame
end

struct Match
    i::Int32
    j::Int32
    dist::Float64
end

struct Normalizer
    means::Array{Float64, 1}
    stds::Array{Float64, 1}

    function Normalizer(dfp::DfPair)
        dfs1, dfs2 = sample.([dfp.df1, dfp.df2])
        raw_dist_arr = [col_dist.(dfs1[!, col], dfs2[!, col]) for col in names(dfs1)]
        means, stds = (mean.(raw_dist_arr), std.(raw_dist_arr))
        nonzero_stds = @. ifelse(stds > 0, stds, 1)
        multiplier =
            [
                (arr .- mu) ./ rho
                for (arr, mu, rho) in zip(raw_dist_arr, means, nonzero_stds)
            ] |>
            mean |>
            std
        new(means, nonzero_stds * multiplier)
    end
end

struct SortedJoiner
    arr::Array{Int, 2}
    sorted_inds::Array{Array{Int, 1}, 1}
    sorted_views::Array{
        SubArray{Int, 1, Array{Int, 2}, Tuple{Array{Int, 1}, Int}, false},
        1,
    }

    function SortedJoiner(arr::Array{Int, 2})
        sinds = [sortperm(arr[:, i]) for i in axes(arr, 2)]
        new(arr, sinds, [view(arr, sinds[i], i) for i in axes(arr, 2)])
    end

    function SortedJoiner(df::DataFrame)
        SortedJoiner(hcat(df[:, 1], df[:, 2]))
    end

end


struct RelPair
    sj1::SortedJoiner
    sj2::SortedJoiner
    colmap::Tuple{String, String}
end

get_pair(base, fp) =
    [ParquetFiles.load(joinpath(base, fp, "$i.parquet")) |> DataFrame for i = 0:1]


struct CorefSystem
    esp_dict::Dict{String, DfPair}
    relps::Array{RelPair, 1}

    function CorefSystem(dir_path::String)
        esp_base, relp_base = [joinpath(dir_path, s) for s in ["esp", "relp"]]
        esp_dict = Dict(
            esp_p => DfPair(get_pair(esp_base, esp_p)...) for esp_p in readdir(esp_base)
        )
        relps = [
            RelPair(
                (SortedJoiner.(get_pair(relp_base, relp_p)))...,
                (JSON.parsefile(joinpath(relp_base, relp_p, "colmap.json")) |> Tuple),
            ) for relp_p in readdir(relp_base)
        ]
        new(esp_dict, relps)
    end
end