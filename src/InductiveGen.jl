module InductiveGen

include("Ast.jl")
using Gen
using .Ast: evaluate, get_all_paths, Expr, Plus, Mult, Div, Var, Const

function make_op(code::Int, left, right) 
    if code == 3
        Plus(left, right)
    elseif code == 4
        Mult(left, right)
    elseif code == 5
        Div(left, right)
    end
end


# This recursively generates random mathematical expression
@gen function generate_expr(depth::Int)
    if depth <= 0
        node_type = @trace(categorical([0.5, 0.5]), :type)

        if node_type == 1
            return Var()
        else
            val = @trace(uniform_discrete(-10, 10), :val)
            return Const(Float64(val))
        end
    else
        node_type = @trace(categorical([0.23, 0.23, 0.18, 0.18, 0.18]), :type)
        if node_type == 1
            return Var()
        elseif node_type == 2
            val = @trace(uniform_discrete(1,5), :val)
            return Const(Float64(val))
        else
            left = @trace(generate_expr(depth - 1), :left)
            right = @trace(generate_expr(depth - 1), :right)
            return make_op(node_type, left, right)
        end
    end
end

function make_gen_address(path::Vector{Symbol})
    if isempty(path)
        return select(:expr)
    end

    addr = path[end]
    for i in length(path)-1:-1:1
        addr = Pair(path[i], addr)
    end

    select(Pair(:expr, addr))
end


@gen function program_model(xs::Vector{Float64}, max_depth::Int)
    expr = @trace(generate_expr(max_depth), :expr)
    for (i, x) in enumerate(xs)
        y_pred = evaluate(expr, x)
        @trace(normal(y_pred, 0.01), (:y, i))
    end
    size = Ast.tree_size(expr)
    @trace(normal(size, 3.0), :size_penalty)
    expr
end

function synthesize_program(xs::Vector{Float64}, ys::Vector{Float64}, max_depth = 4, steps_per_depth = 10_000) 
    println("Input ⌨️: $xs => Target 🎯: $ys")

    observations = choicemap()
    for (i, y) in enumerate(ys)
        observations[(:y, i)] = y
    end
    observations[:size_penalty] = 1.0

    for depth in 0:max_depth
        println("Searching at depth: $depth")

        trace, _ = generate(program_model, (xs, depth), observations) 

        min_error = Inf
        best_program = Nothing
        for step in 1:steps_per_depth
            current_program = get_retval(trace)
            valid_paths = Ast.get_all_paths(current_program)

            target_path = rand(valid_paths)
            target_selection = make_gen_address(target_path)

            trace, accepted = mh(trace, target_selection)
            current_program = get_retval(trace)
            total_error = sum(abs(Ast.evaluate(current_program, xs[i]) - ys[i]) for i in 1:length(xs))

            if total_error < min_error
                min_error = total_error
                best_program = current_program
            end
        end

        print("Best program at depth $depth, error $min_error: $best_program")
    end
end

end # module InductiveGen
