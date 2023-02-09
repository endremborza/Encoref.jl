
function extend!(
    crr::CorefResolver,
    params::ExtendParams,
    )
    source_pair, target_pair = crr |> innerspaces
    rel_pair = crr.crs.relps[params.rel_pair_ind]

    for (source_space, target_space, joiner) in zip(
            [source_pair.erspace1, source_pair.erspace2], 
            [target_pair.erspace1, target_pair.erspace2],
            [rel_pair.sj1, rel_pair.sj2]
            )
        extend!(source_space, target_space, joiner, params.root_side)    
        target_space.entity_types = source_space.entity_types
        m = target_space.width
        target_space.entity_types[m] = rel_pair.colmap[other(params.root_side)]
    end
end

function extend!(
    source_space::EntityRefSpace,
    target_space::EntityRefSpace,
    joiner::SortedJoiner,
    side::Int,
    )
    opp = other(side)
    source_arr = source_space.space
    target_arr = target_space.space

    n_source = source_space.height
    m_source = source_space.width

    i_target = 0
    m_target = m_source + 1
    # @inbounds 
    for i_source in 1:n_source
        for j in searchsorted(joiner.sorted_views[side], source_arr[i_source, m_source])
            i_target += 1
            # inbounds problem - planning needed
            for k in 1:m_source target_arr[i_target, k] = source_arr[i_source, k] end
            target_arr[i_target, m_source + 1] = joiner.arr[joiner.sorted_inds[side][j], opp]
        end
    end
    target_space.width = m_target
    target_space.height = i_target
end
