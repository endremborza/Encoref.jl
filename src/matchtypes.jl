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
    means::Array{Real, 1}
    stds::Array{Real, 1}
end

struct SortedJoiner
    arr::Array{Int, 2}
    sorted_inds::Array{Array{Int, 1}, 1}
    sorted_views::Array{
        SubArray{Int, 1, Array{Int, 2}, Tuple{Array{Int, 1}, Int}, false},
        1,
    }
end

struct RelPair
    sj1::SortedJoiner
    sj2::SortedJoiner
    colmap::Tuple{String, String}
end

struct CorefSystem
    esp_dict::Dict{String, DfPair}
    relps::Array{RelPair, 1}
end
