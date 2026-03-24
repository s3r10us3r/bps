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

struct If <: Expr 
    cond::Const # condition is always x > cond
    true_branch::Expr
    false_branch::Expr
end

tree_size(op::If) = 2 + tree_size(op.cond) + tree_size(op.true_branch) + tree_size(op.false_branch)
tree_size(::Var) = 1
tree_size(::Const) = 1
tree_size(op::ArithmeticOp) = 1 + tree_size(op.left) + tree_size(op.right)

tree_depth(::Var) = 0
tree_depth(::Const) = 0
tree_depth(op::ArithmeticOp) = 1 + max(tree_depth(op.left), tree_depth(op.right))
tree_depth(op::If) = 1 + max(tree_depth(op.cond), tree_depth(op.true_branch), tree(op.false_branch))

operator(::Plus) = +
operator(::Mult) = *
operator(::Div) = /

evaluate(::Var, x::Float64) = x
evaluate(c::Const, x::Float64) = c.val
evaluate(op::ArithmeticOp, x::Float64) = operator(op)(evaluate(op.left, x), evaluate(op.right, x))

function evaluate(op::If, x::Float64)
    if x > op.cond.val
        evaluate(op.true_branch, x)
    else
        evaluate(op.false_branch, x)
    end
end

symbol(::Plus) = "+"
symbol(::Mult) = "*"
symbol(::Div) = "/"

Base.show(io::IO, ::Var) = print(io, "x")
Base.show(io::IO, c::Const) = print(io, c.val)
Base.show(io::IO, op::ArithmeticOp) = print(io, "(", op.left, symbol(op), op.right, ")")
Base.show(io::IO, op::If) = print(io, "if x > ", op.cond.val, " { ", op.true_branch, " } ", "else { " , op.false_branch, " }")

function get_all_paths(expr::Expr, current_path::Vector{Symbol}=Symbol[]) 
    paths = [current_path]

    if expr isa ArithmeticOp
        append!(paths, get_all_paths(expr.left, [current_path..., :left]))
        append!(paths, get_all_paths(expr.right, [current_path..., :right]))
    elseif expr isa If
        append!(paths, get_all_paths(expr.cond, [current_path..., :cond]))
        append!(paths, get_all_paths(expr.true_branch, [current_path..., :true_branch]))
        append!(paths, get_all_paths(expr.false_branch, [current_path..., :false_branch]))
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
    elseif direction == :cond
        return get_node(expr.cond, rest)
    elseif direction == :true_branch
        return get_node(expr.true_branch, rest)
    elseif direction == :false_branch
        return get_node(expr.false_branch, rest)
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
    elseif expr isa If
        if direction == :cond
            return If(new_node, expr.true_branch, expr.false_branch)
        elseif direction == :true_branch
            return If(expr.cond, replace_node(expr.true_branch, rest, new_node), expr.false_branch)
        elseif direction == :false_branch
            return If(expr.cond, expr.true_branch, replace_node(expr.false_branch, rest, new_node))
        end
    end
end

end
