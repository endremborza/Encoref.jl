function init!(
    crr::CorefResolver,
    params::InitParams,
    )
    
    df_pair = crr.crs.esp_dict[params.entity_type]
    space_pair = crr |> main
    for (samp_n, refspace, df) in 
        zip(
            [params.left_sample, params.right_sample], 
            [space_pair.erspace1, space_pair.erspace2], 
            [df_pair.df1, df_pair.df2]
            )
        init!(refspace, df, params.entity_type, samp_n)
    end
end

function init!(
    refspace::EntityRefSpace, 
    df::DataFrame,
    entity_type::String,
    sample_size::Int,
    )
    refspace.width = 1
    refspace.entity_types[1] = entity_type
    dfh = size(df)[1]
    spacemaxh = size(refspace.space)[1]
    # TODO: warn about this next bit
    # note it in progress
    (sample_size > spacemaxh) && (sample_size = spacemaxh)
    if sample_size > dfh
        refspace.space[1:dfh, 1] = 1:dfh
        refspace.height = dfh
    else
        refspace.space[1:sample_size, 1] = StatsBase.sample(1:dfh, sample_size, replace=false)
        refspace.height = sample_size
    end
end
