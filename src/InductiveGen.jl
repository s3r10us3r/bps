module InductiveGen

include("Ast.jl")
using Gen
using .Ast: evaluate, get_all_paths, Expr, Plus, Mult, Div, Var, Const, If

@gen function generate_const(const_range::Tuple{Int, Int})
    val = round(@trace(uniform(const_range[1], const_range[2]), :val), digits=2)
    return Const(Float64(val))
end

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
@gen function generate_expr(depth::Int, allow_const::Bool=true, allow_if::Bool=true, const_range::Tuple{Int, Int}=(-100, 100))
    if depth <= 0
        probs = allow_const ? [0.5, 0.5] : [1.0, 0.0]
        node_type = @trace(categorical(probs), :type)

        if node_type == 1
            return Var()
        else
            val = round(@trace(uniform(const_range[1], const_range[2]), :val), digits=2)
            return Const(Float64(val))
        end
    end

    if allow_if
        is_if = @trace(bernoulli(0.1), :is_if)

        if is_if
            cond = @trace(generate_const(const_range), :cond)
            true_branch = @trace(generate_expr(depth - 1, true, true, const_range), :true_branch)
            false_branch = @trace(generate_expr(depth - 1, true, true, const_range), :false_branch)
            return If(cond, true_branch, false_branch)
        end
    end


    probs = allow_const ? [0.23, 0.23, 0.18, 0.18, 0.18] : [0.35, 0.0, 0.21, 0.22, 0.22]
    node_type = @trace(categorical(probs), :type)
    if node_type == 1
        return Var()
    elseif node_type == 2
        val = round(@trace(uniform(const_range[1], const_range[2]), :val), digits=2)
        return Const(Float64(val))
    else
        left = @trace(generate_expr(depth - 1, true, false, const_range), :left)
        right_can_be_const = !(left isa Const)

        right = @trace(generate_expr(depth - 1, right_can_be_const, false, const_range), :right)

        return make_op(node_type, left, right)
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
        @trace(normal(y_pred, 0.1), (:y, i))
    end
    size = Ast.tree_size(expr)
    @trace(normal(size, 10.0), :size_penalty)
    expr
end

function synthesize_program(xs::Vector{Float64}, ys::Vector{Float64}, max_depth = 4, steps_per_depth = 10_000) 
    println("Input ⌨️: $xs => Target 🎯: $ys")

    observations = choicemap()
    for (i, y) in enumerate(ys)
        observations[(:y, i)] = y
    end
    observations[:size_penalty] = 1.0

    best_program = nothing
    min_error = Inf
    best_trace = nothing

    for depth in 0:max_depth
        println("Searching at depth: $depth")

        if best_trace == nothing
            trace, _ = generate(program_model, (xs, depth), observations) 
        else
            trace, _, _, _ = update(best_trace, (xs, depth), (Gen.NoChange(), Gen.UnknownChange()), choicemap())
        end

        local_min_error = Inf
        local_best_program = nothing

        for step in 1:steps_per_depth
            current_program = get_retval(trace)
            valid_paths = Ast.get_all_paths(current_program)

            target_path = rand(valid_paths)
            target_selection = make_gen_address(target_path)

            trace, accepted = mh(trace, target_selection)
            current_program = get_retval(trace)
            total_error = sum(abs(Ast.evaluate(current_program, xs[i]) - ys[i]) for i in 1:length(xs))

            if total_error < local_min_error
                local_min_error = total_error
                local_best_program = current_program
                best_trace = trace
            end
        end

        println("Best program at depth $depth, error $local_min_error: $local_best_program")
        if local_min_error < min_error
            min_error = local_min_error
            best_program = local_best_program
        end
    end
    println("Best program found:")
    println("$best_program")
    println("Error: $min_error")
end

end # module InductiveGen
