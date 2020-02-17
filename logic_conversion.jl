using Match

struct Relation
    name::String
end

struct Concept
    name::String
end

struct Object
    name::String    # Mary
end

Atom = Union{Relation, Concept, Object, Symbol}
Expression = Union{Array{Atom}, Atom}
Tbox = Dict{Concept, Atom}
Abox = Array{Expression}


function move_not_inward(expression)
    conversion = @match expression begin
        [:not, [:or, P, Q]]              => [:and, [:not, P], [:not, Q]]
        [:not, [:and, P, Q]]             => [:or, [:not, P], [:not, Q]]
        [:not, [:not, P]]                => P
        [:not, [:exists, [:rule, R, C]]] => [:all, [:rule, R, [:not, C]]]
        [:not, [:all, [:rule, R, C]]]    => [:exists, [:rule, R, [:not, C]]]   
        X                                => X
    end

    return @match conversion begin
        s::Atom => s
        e::Array => map(move_not_inward, e)
    end
end



# Converts expression to negation normal form
function eliminate_implication(expression)
    conversion = @match expression begin
      [:implies, P, Q]                 => [:or, [:not, P], Q]
      [:double_implies, P, Q]          => [:and, [:or, P, [:not, Q]], [:or, [:not, P], Q]]
      X                                => X
    end

    return @match conversion begin
        s::Atom => s
        e::Array => map(eliminate_implication, e)
    end
end


function nnf(expression)
    expression = eliminate_implication(expression)

    prev_exp = nothing
    while expression != prev_exp
        prev_exp = expression
        expression = move_not_inward(expression)
    end
    return expression
end

### Concept Expansion ###

function expand_concepts(a_box::Array, t_box::Dict)
    # T box maps symbols to expressions (symbol or array of symobls)
    expanded_abox = map(expression -> expand_concept(expression, t_box), a_box)
    return expanded_abox
end

function expand_concept(expression, t_box::Dict)

    recursive_expand_concept(exp) = expand_concept(exp, t_box) 
    
    if isa(expression, Concept)
        expression = get(t_box, expression, expression)
    end
    
    return @match expression begin
        s::Atom => s
        e::Array => map(recursive_expand_concept, e)
    end
end

function change_premise(expression)
    @match expression begin
        [:subsumes, X, Y] => return [:apply, [:and, X, [:not, Y]], Object("_a")]
    end
    throw(ArgumentError("expression must contain the symbol :subsumes"))
end

function tableau(abox, tbox, premise)
    # Premise: Subsumption Question
    abox = expand_concepts(collect(abox), tbox)
    negated_premise = change_premise(premise)
    push!(abox, negated_premise) 
    
    abox = map(nnf, collect(abox)) 
    print(abox)
end
