struct DfPair
    df1::DataFrame
    df2::DataFrame
end

abstract type AbstractMatch end

struct Match <: AbstractMatch
    i::Int
    j::Int
    dist::Real
end

struct HalfMatch <: AbstractMatch
    ind::Int
    dist::Real
end

isless(x::AbstractMatch, y::AbstractMatch) = x.dist < y.dist;

abstract type StepParameters end

struct InitParams <: StepParameters
    entity_type::String
    left_sample::Int 
    right_sample::Int
end

struct ExtendParams <: StepParameters
    rel_pair_ind::Int
    root_side::Int
end

struct MatchParams <: StepParameters
    needed_matches::Int
end

struct IntegrateParams <: StepParameters end

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
    normalizers::Dict{String, Normalizer}
    relps::Array{RelPair, 1}
end

mutable struct EntityRefSpace
    space::Array{Int, 2}
    height::Int
    width::Int
    entity_types::Array{String, 1}
end

struct SpacePair
    erspace1::EntityRefSpace
    erspace2::EntityRefSpace
end

heights(space_pair::SpacePair) = (space_pair.erspace1.height, space_pair.erspace2.height)
spaces(space_pair::SpacePair) = (space_pair.erspace1, space_pair.erspace2)
innerspaces(space_pair::SpacePair) = (ers.space for ers in spaces(space_pair))


mutable struct CorefProposal
    ind::Int
    latent_vars::Array{Real,1}
end

struct CorefSpace
    latent_match_vars::Dict{String, Array{Array{CorefProposal,1},1}}
    prepspace::Array{HalfMatch, 2}
    free_i::Array{Bool, 1}
    free_j::Array{Bool, 1}
    param_log::Array{StepParameters, 1}
end

mutable struct CorefResolver
    crs::CorefSystem
    crspace::CorefSpace
    space_pairs::Tuple{SpacePair, SpacePair}
    leftspace_main::Bool
end

function valid(proposal::CorefProposal)
    proposal.ind > 0
end

function parse(lvars::Array{Array{CorefProposal,1},1})
    out = Array{Array{Int, 2}, 1}()
    for (fun, lvar_arr) in zip([x -> x, reverse], lvars)
        for (i, propsal) in enumerate(lvar_arr)
            if valid(propsal)
                r = reshape(fun([i, propsal.ind]), (1, 2))
                (r in out) && continue 
                push!(out, r)
            end
        end
    end
    vcat(out...)
end

result(crr::CorefResolver) = Dict(name=> parse(lvars) for (name, lvars) in crr.crspace.latent_match_vars)
main(crr::CorefResolver) = crr.space_pairs[crr.leftspace_main ? 1 : 2]
innerspaces(crr::CorefResolver) = (crr.leftspace_main ? x -> x : reverse)(crr.space_pairs)
switch!(crr::CorefResolver) = (crr.leftspace_main = !crr.leftspace_main)
