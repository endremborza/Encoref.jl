

Match() = Match(-1, -1, Inf)

HalfMatch() = HalfMatch(-1, Inf)


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

function RelPair(rels::Array, colmap::Tuple{String, String})
    RelPair(SortedJoiner.(rels)...,colmap)
end

CorefProposal() = CorefProposal(-1, fill(0.0, 5))  # Latent variable count

function CorefSpace(longside::Int, shortside::Int, preplen::Int)
    latent_match_vars = Dict(
        k=> [[CorefProposal() for _ in  1:size(df)[1]] 
        for df in [dfp.df1, dfp.df2]] for (k, dfp) in crs.esp_dict
    );
    prepspace = fill(HalfMatch(),(shortside, preplen))
    free_i = fill(false, shortside)
    free_j = fill(false, longside)
    CorefSpace(latent_match_vars, prepspace, free_i, free_j, [])
end

function CorefSystem(esp_dict::Dict{String, DfPair}, relps::Array{RelPair})
    normalizers = Dict(k=>Normalizer(dfp) for (k, dfp) in esp_dict)
    CorefSystem(esp_dict, normalizers, relps, Dict(k=>Set() for k in keys(esp_dict)))    
end

function CorefSystem(dir_path::String)
    esp_base, relp_base = [joinpath(dir_path, s) for s in ["esp", "relp"]]
    esp_dict = Dict(
        esp_p => DfPair(load_dfs(esp_base, esp_p)...) for esp_p in readdir(esp_base)
    )
    relps = [
        RelPair(
            SortedJoiner.(load_dfs(relp_base, relp_p))...,
            JSON.parsefile(joinpath(relp_base, relp_p, "colmap.json")) |> Tuple
            ) 
        for relp_p in readdir(relp_base)
    ]
    CorefSystem(esp_dict,relps)
end

function SpacePair(maxh1::Int, maxh2::Int, maxw::Int)
    SpacePair([
        EntityRefSpace(
            Array{Int,2}(undef, x, maxw),
            0,
            0,
            Array{String}(undef, maxw))
             for x in [maxh1, maxh2]]...
                )
end

function CorefResolver(
    crs::CorefSystem,
    shortside::Int,
    longside::Int,
    max_depth::Int,
    preplen::Int,
    )
    CorefResolver(
        crs,
        CorefSpace(longside, shortside, preplen),
        Tuple(SpacePair(shortside, longside, max_depth) for _ in 1:2),
        true,
    )
end

InitParams(entity_type::String) = InitParams(entity_type, typemax(Int), typemax(Int))