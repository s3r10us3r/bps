module Ast

abstract type Expr end

struct Var <: Expr end
struct Const <: Expr
    val::Float64
end

abstract type ArithmeticOp <: Expr end


struct Plus <: ArithmeticOp
    left::Expr
    right::Expr
end

struct Mult <: ArithmeticOp
    left::Expr
    right::Expr
end

struct Div <: ArithmeticOp
    left::Expr
    right::Expr
end

tree_size(::Var) = 1
tree_size(::Const) = 1
tree_size(op::ArithmeticOp) = 1 + tree_size(op.left) + tree_size(op.right)

tree_depth(::Var) = 0
tree_depth(::Const) = 0
tree_depth(op::ArithmeticOp) = 1 + max(tree_depth(op.left), tree_depth(op.right))

operator(::Plus) = +
operator(::Mult) = *
operator(::Div) = /

evaluate(::Var, x::Float64) = x
evaluate(c::Const, x::Float64) = c.val
evaluate(op::ArithmeticOp, x::Float64) = operator(op)(evaluate(op.left, x), evaluate(op.right, x))

symbol(::Plus) = "+"
symbol(::Mult) = "*"
symbol(::Div) = "/"



Base.show(io::IO, ::Var) = print(io, "x")
Base.show(io::IO, c::Const) = print(io, c.val)
Base.show(io::IO, op::ArithmeticOp) = print(io, "(", op.left, symbol(op), op.right, ")")

function get_all_paths(expr::Expr, current_path::Vector{Symbol}=Symbol[]) 
    paths = [current_path]

    if expr isa ArithmeticOp
        append!(paths, get_all_paths(expr.left, [current_path..., :left]))
        append!(paths, get_all_paths(expr.right, [current_path..., :right]))
    end

    paths
end

function get_node(expr::Expr, path::Vector{Symbol}) 
    if isempty(path)
        return expr
    end

    direction, rest... = path

    if direction == :left
        return get_node(expr.left, rest)
    elseif direction == :right
        return get_node(expr.right, rest)
    else
        error("Invalid path direction: $direction")
    end
end

function replace_node(expr::Expr, path::Vector{Symbol}, new_node::Expr)
    if isempty(path)
        return new_node
    end

    direction, rest... = path

    if expr isa ArithmeticOp
        OpType = typeof(expr)
        if direction == :left
            return OpType(replace_node(expr.left, rest, new_node), expr.right)
        elseif direction == :right
            return OpType(expr.left, replace_node(expr.right, rest, new_node))
        end
    end
end

end
