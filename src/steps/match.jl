function match!(
    crr::CorefResolver,
    params::MatchParams,
    )
    #TODO: erspace1 needs to be the smaller
    #after extensions and restarts this needs to be verified
    source_pair, target_pair = crr |> innerspaces

    crs = crr.crs
    crspace = crr.crspace

    n1 = source_pair.erspace1.height
    n2 = source_pair.erspace2.height
    w = source_pair.erspace1.width
    crspace.free_i[1:n1] .= true
    crspace.free_j[1:n2] .= true
    prepspace = crspace.prepspace
    prepw = size(prepspace)[2]

    _distfun(i::Int, j::Int) = dist(source_pair, crs, i, j)

    prepmatch!(_distfun, prepspace, n1, n2)

    match_count = 0
    best_match = Match()
    while match_count < params.needed_matches
        best_dist = Inf
        @inbounds for i in 1:n1
            !crspace.free_i[i] && continue
            new_match = prepspace[i, 1]
            new_match.dist > best_dist && continue
            
            if !crspace.free_j[new_match.ind]
                for k in 1:prepw-1
                    prepspace[i, k] = prepspace[i, k+1] 
                end                
                if prepspace[i, 1].ind == -1
                    (_j, _dist) = min_ind_of_free(x -> _distfun(i, x), n2, crspace.free_j)
                    prepspace[i, 1] = HalfMatch(_j, _dist)
                else
                    prepspace[i, prepw] = HalfMatch()
                end
                new_match = prepspace[i, 1]
            end
            
            if new_match.dist < best_dist
                best_dist = new_match.dist
                best_match = Match(i, new_match.ind, new_match.dist)
            end

        end
        crspace.free_i[best_match.i] = false
        crspace.free_j[best_match.j] = false
        match_count += 1
        for (_sarr, _tarr, ind) in zip(
            [source_pair.erspace1, source_pair.erspace2],
            [target_pair.erspace1, target_pair.erspace2],
            [best_match.i, best_match.j])

            for k in 1:w _tarr.space[match_count, k] = _sarr.space[ind, k] end
        end    
    end
    for erspace in target_pair |> spaces
        erspace.height = match_count
        erspace.width = w
        erspace.entity_types = source_pair.erspace1.entity_types
    end
    target_pair.erspace1.height = match_count
    target_pair.erspace2.height = match_count
end


const MATCH_DIST = -10.0
const PATH_DISCOUNT = 0.8

function dist(crs::CorefSystem, name::String, i::Int, j::Int)
    if (i, j) in crs.dict_of_matches[name]  # TODO: from latent vars
        return MATCH_DIST
    end
    dfp = crs.esp_dict[name]
    normalizer = crs.normalizers[name]
    s = 0.0
    for (colname, mu, rho) in zip(names(dfp.df1), normalizer.means, normalizer.stds)
        s += @inbounds (col_dist(dfp.df1[i,colname], dfp.df2[j,colname]) - mu) / rho
    end
    s #/ length(normalizer.means)
end

function dist(space_pair::SpacePair, crs::CorefSystem, i::Int, j::Int)
    s = 0.0
    for l in 1:space_pair.erspace1.width
        name = space_pair.erspace1.entity_types[l]
        ent_ind_i = space_pair.erspace1.space[i, l]
        ent_ind_j = space_pair.erspace2.space[j, l]
        s += dist(crs, name, ent_ind_i, ent_ind_j) * PATH_DISCOUNT ^ (l-1)
    end
    s
end


function min_ind_of_free(fun::Function, n::Int, free_inds::Array{Bool})
    m = Inf
    j = -1
    for i in 1:n
        !free_inds[i] && continue
        d = fun(i)
        d < m && (j = i; m = d)
    end
    (j, m)
end


function prepmatch!(
    distfun::Function,
    prepspace::Array{HalfMatch, 2},
    n1::Int,
    n2::Int
    )
    prep_size = size(prepspace)[2]
    for i in 1:n1
        prepv = prepspace[i, :]
        prepmax = Inf
        fill!(prepv, HalfMatch())
        for j in 1:n2
            d = distfun(i, j)
            if d < prepmax
                new_match = HalfMatch(j, d)
                pind = searchsortedfirst(prepv, new_match)
                pind < prep_size && (prepv[pind+1:prep_size] = prepv[pind:prep_size-1])
                prepv[pind] = new_match
                prepmax = prepv[prep_size].dist
            end
        end
    end
end
