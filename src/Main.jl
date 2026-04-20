include("InductiveGen.jl")

using .InductiveGen
using Random

# y = x^2 + 2x + 5
function polynomial()
    xs = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]
    ys = [8.0, 5.0, 4.0, 5.0, 8.0, 13.0, 20.0]
    InductiveGen.synthesize_program(xs, ys, 6, 100_000)
end


function polynomial_noised()
    Random.seed!(42)
    noise_std = 1.5

    xs = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]
    ys = [8.0, 5.0, 4.0, 5.0, 8.0, 13.0, 20.0]
    ys_noisy = ys .+ (randn(length(ys)) .* noise_std)
    InductiveGen.synthesize_program(xs, ys_noisy, 6, 100_000)
end

function partitioned()
    xs = [-3.0, -2.0, -1.0, 1.0, 2.0, 3.0, 5.0]
    ys = [3.0, 2.0, 1.0, 2.0, 4.0, 6.0, 10.0]
    InductiveGen.synthesize_program(xs, ys, 6, 100_000)
end

function partitioned_err()
    Random.seed!(42)
    noise_std = 1.5

    xs = [-3.0, -2.0, -1.0, 1.0, 2.0, 3.0, 5.0]
    ys = [3.0, 2.0, 1.0, 2.0, 4.0, 6.0, 10.0]
    ys_noisy = ys .+ (randn(length(ys)) .* noise_std)
    InductiveGen.synthesize_program(xs, ys_noisy, 6, 100_000)
end

function presentation()
    xs = [-3.0, -2.0, -1.0, 1.0, 2.0, 3.0, 5.0]
    ys = Float64[]
    for x in xs
        ny = (x > 0 ? x*x + 2*x + 5 : -x + 5)
        append!(ys, ny)
    end
    InductiveGen.synthesize_program(xs, ys, 6, 100_000)
end

function presentation_noised()
    noise_std = 1.5
    xs = [-3.0, -2.0, -1.0, 1.0, 2.0, 3.0, 5.0]
    ys = Float64[]
    for x in xs
        ny = x * x + 2 * x + 3
        append!(ys, ny)
    end
    ys_noisy = ys .+ (randn(length(ys)) .* noise_std)
    InductiveGen.synthesize_program(xs, ys_noisy, 6, 1_000_000)
end

function main() 
    xs = [-5.0, -3.0, -1.0, 2.0, 5.0, 8.0, 12.0, 15.0, 20.0]
    ys = [-5.0, -3.0, -1.0, 7.0, 10.0, 13.0, 24.0, 30.0, 40.0]
    InductiveGen.synthesize_program(xs, ys, 6, 100_000)
end

