include("InductiveGen.jl")

using .InductiveGen

xs = [1.0, 2.0, 3.0, 4.0, 5.0]
ys = [-1.0, 2.0, 7.0, 14.0, 23.0]
InductiveGen.synthesize_program(xs, ys, 6, 100_000)

