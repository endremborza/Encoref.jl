module Encoref
using DataFrames, JSON
using StringDistances, Statistics, DataStructures, Random, Pipe
import ParquetFiles
import Base: isless


include("utils.jl")
include("matchtypes.jl")
include("constructors.jl")
include("steps/init.jl")
include("steps/extend.jl")
include("steps/match.jl")
include("steps/integrate.jl")
include("steps/common.jl")

export CorefSystem, coref

end
