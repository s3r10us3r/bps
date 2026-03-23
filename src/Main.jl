include("InductiveGen.jl")

using .InductiveGen

xs = [1.0, 2.0, 3.0, 4.0, 5.0]
# x^2 - 5
ys = (xs .^ 2 .- 5) .* 2 .+ 3

InductiveGen.synthesize_program(xs, ys, 6, 100_000)

