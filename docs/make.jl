using Encoref
using Documenter

makedocs(;
    modules=[Encoref],
    authors="Endre Márk Borza",
    repo="https://github.com/endremborza/Encoref.jl/blob/{commit}{path}#L{line}",
    sitename="Encoref.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://endremborza.github.io/Encoref.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/endremborza/Encoref.jl",
)
