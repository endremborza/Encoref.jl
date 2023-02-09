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

include("../test/testutils.jl")

## GEN

esp_dic = Dict("fing"=> generate_dfpair(3,1,0))
relp = RelPair([[1 1; 1 2;2 2], [2 2; 2 1]], ("fing", "fing"))
crs = CorefSystem(esp_dic, [relp])

shortside = 10
longside = 10
max_depth = 3
preplen = 3

crr = CorefResolver(crs, shortside, longside, max_depth, preplen);

steps = [
    InitParams("fing"),
    ExtendParams(1, 1),
    MatchParams(2),
    IntegrateParams(),
]

step!(crr, steps[1])


crr.leftspace_main
crr.space_pairs[1]
crr.space_pairs[2]


for erspace in crr |> main |> spaces
    (erspace.width == 1) |> println
    (erspace.height == 3) |> println
    (erspace.space[1:3,1] == [1, 2, 3]) |> println
end

step!(crr, steps[2])

(crr |> main).erspace1.width == 2
(crr |> main).erspace1.space[1:3, 1:2] == [1 1; 1 2; 2 2]

(crr |> main).erspace1.space[1:7,:]

step!(crr, steps[3])


crr.leftspace_main
crr.space_pairs[1]
crr.space_pairs[2]

(crr |> main).erspace1.space
(crr |> main).erspace2.space


step!(crr, steps[4])

crr.crspace.latent_match_vars

### FILE:
crsysarr = [CorefSystem("./test/test_data/test_sys_$i") for i in 0:2]

crs = crsysarr[1]

shortside = 600
longside = 200
max_depth = 3
preplen = 5

crr = CorefResolver(crs, shortside, longside, max_depth, preplen);

steps = [
    InitParams("e"),
    MatchParams(8),
    IntegrateParams(),
]

for params in steps
    step!(crr, params)
end

step!(crr, steps[end])

(crr |> main).erspace1.width#space[1:8,:]

res = crr |> result

tres0 = load_result("./test/test_data/test_sys_0")

res["e"] == tres0["e"]
