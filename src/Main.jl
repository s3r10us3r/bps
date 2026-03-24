include("InductiveGen.jl")

using .InductiveGen

function main() 
    xs = [-5.0, -3.0, -1.0, 2.0, 5.0, 8.0, 12.0, 15.0, 20.0]
    ys = [-5.0, -3.0, -1.0, 7.0, 10.0, 13.0, 24.0, 30.0, 40.0]
    InductiveGen.synthesize_program(xs, ys, 6, 100_000)
end

