using StringDistances, Statistics, DataStructures, Random, Pipe

import Base: isless
import Base.Threads.@spawn
import Base.Threads.@threads

include("matchtypes.jl")

const SAMPLES_FOR_DIST_NORMER = 50000;

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
    CorefSystem(esp_dict, relps)
end


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
    Normalizer(means, nonzero_stds * multiplier)
end

function SortedJoiner(arr::Array{Int, 2})
    sinds = [sortperm(arr[:, i]) for i in axes(arr, 2)]
    SortedJoiner(arr, sinds, [view(arr, sinds[i], i) for i in axes(arr, 2)])
end

SortedJoiner(df::DataFrame) = SortedJoiner(hcat(df[:, 1], df[:, 2]))

get_pair(base, fp) = [ParquetFiles.load(joinpath(base, fp, "$i.parquet")) |> DataFrame for i = 0:1]

col_dist(x::String, y::String) = evaluate(normalize(Levenshtein()), x::String, y::String);
col_dist(x::Number, y::Number) = abs(x - y);
sample(df::DataFrame) = @inbounds df[rand(1:nrow(df), SAMPLES_FOR_DIST_NORMER), :];
isless(x::Match, y::Match) = x.dist < y.dist;
idsort(t::Tuple{Int, Int}) = t[1] < t[2] ? (1, 2, t[1], false) : (2, 1, t[2], true);


function get_dists(dfp::DfPair, normalizer::Normalizer)
    mean([
        [(col_dist(x, y) - mu) / rho for x in dfp.df1[!,colname], y in dfp.df2[!,colname]] 
        for (colname, mu, rho) in zip(names(dfp.df1), normalizer.means, normalizer.stds)
    ])
end


function subrange_ind(arr, subrange, indset)
    m = Inf
    ind = 0
    for i in subrange
        if (arr[i] < m) && !(i in indset)
            m = arr[i]
            ind = i
        end
    end
    ind
end

function dropped_min_ind(a, drop_inds)
    l = length(a)
    tn = Threads.nthreads()
    sizes = (l ÷ tn) + 1
    iter = collect(pairs(1:sizes:l))
    out = Array{Int, 1}(undef, length(iter))
    @threads for (i, s) in iter
        send = min(s + sizes - 1, l)
        out[i] = @inbounds subrange_ind(a, s:send, drop_inds)
    end
    subrange_ind(a, filter(x -> x > 0, out), drop_inds)
end


function get_ind_pairs(distance_matrix::Array{Float64, 2})
    (i1, i2, s1, flipper) = idsort(size(distance_matrix))
    flip(x, y) = flipper ? (y, x) : (x, y)
    @pipe (h = BinaryMinHeap{Match}()) |> sizehint!(_, s1)

    j_matched = Set{Int}()
    dropped_sets = fill(Set{Int}(), s1)
    matches = Array{Int, 2}(undef, s1, 2)

    @inbounds for i = 1:s1
        best_pair = dropped_min_ind(distance_matrix[flip(i, :)...], dropped_sets[i])
        best_d = distance_matrix[flip(i, best_pair)...]
        push!(h, Match(i, best_pair, best_d))
    end
    matched = 0
    while matched < s1
        top_match = pop!(h)
        if (top_match.j in j_matched)
            push!(dropped_sets[top_match.i], top_match.j)
            new_pair = dropped_min_ind(
                distance_matrix[flip(top_match.i, :)...],
                dropped_sets[top_match.i],
            )
            new_dist = distance_matrix[flip(top_match.i, new_pair)...]
            new_match = Match(top_match.i, new_pair, new_dist)
            push!(h, new_match)
        else
            push!(j_matched, top_match.j)
            matched += 1
            @inbounds matches[top_match.i, i2] = top_match.j
            @inbounds matches[top_match.i, i1] = top_match.i
        end
    end
    matches
end


function match_entities(
    entity_pairs::Array{DfPair, 1},
    relation_pairs::Array{DfPair, 1} = Array{DfPair, 1}(undef, 0),
)
    normalizers = Normalizer.(entity_pairs)
    distance_dicts = fill(Dict{CartesianIndex{2}, Float64}(), length(entity_pairs))
    return [
        get_ind_pairs(get_dists(dfp, normer))
        for (dfp, normer) in zip(entity_pairs, normalizers)
    ]
end


function coref(corefsys::CorefSystem)
    normalizers = Normalizer.(corefsys.esp_dict |> values)

    
    return Dict(esp_name=>get_ind_pairs(get_dists(dfp, normer))
        for ((esp_name, dfp), normer) in zip(corefsys.esp_dict, normalizers)
    )
end
