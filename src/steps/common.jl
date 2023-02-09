function step!(crr::CorefResolver, params::StepParameters)
    _step!(crr, params)
    push!(crr.crspace.param_log, params)
end

function _step!(crr::CorefResolver, params::InitParams)
   empty!(crr.crspace.param_log)
   init!(crr, params)
end

function _step!(crr::CorefResolver, params::ExtendParams)
    extend!(crr, params)
    crr |> switch!
end

function _step!(crr::CorefResolver, params::MatchParams)
    match!(crr, params)
    crr |> switch!
end

function _step!(crr::CorefResolver, params::IntegrateParams)
    integrate!(crr)
end