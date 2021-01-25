function integrate!(crr::CorefResolver)
    # top_n matches are taken
    # need to of how many
    space_pair = crr |> main
    crspace = crr.crspace
    crs = crr.crs

    inner_spaces = space_pair |> innerspaces |> collect
    n = space_pair.erspace1.height
    space_fit = get_space_fit(space_pair)
    for k in 1:space_pair.erspace1.width
        name = space_pair.erspace1.entity_types[k]
        for space_ind in 1:n
            for (thisspace, otherspace, lspace) in zip(inner_spaces, reverse(inner_spaces), crr.crspace.latent_match_vars[name])
                i1 = thisspace[space_ind, k]
                i2 = otherspace[space_ind, k]
                proposal = lspace[i1]
                println(i1, i2)
                update!(proposal, i2, crr.crspace.param_log, space_fit)
            end            
        end
    end
end

function update!(
    proposal::CorefProposal, 
    match::Int, 
    steplog::Array{StepParameters, 1}, 
    space_fit
    )
    proposal.ind = match
end

function get_space_fit(space_pair::SpacePair)
    10
end