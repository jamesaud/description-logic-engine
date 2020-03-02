using Match

function printbox(box)
    for item in box
        print(item)
        print("\n")
    end
end

function printboxes(boxes)
    for box in boxes
        printbox(box)
        print("\n\n\n")
    end
end

struct Relation
    name::String
end

struct Concept
    name::String
end

struct Object
    name::String    # Mary
end

Atomic = Union{Relation, Concept, Object, Symbol}
Expression = Union{Array{Atomic}, Atomic}
Tbox = Dict{Concept, Atomic}
Abox = Array{Expression}

__nextVar = 0

function next_var()
    global __nextVar
    __nextVar += 1
    return string(__nextVar)
end

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
        e::Array => map(move_not_inward, e)
        s => s
    end
end


function nnf(expression)
    prev_exp = nothing
    while expression != prev_exp
        prev_exp = expression
        expression = move_not_inward(expression)
    end
    return expression
end

function nnf_abox(abox)
    new_abox = Set()
    for exp in abox
        exp = nnf(exp)
        push!(new_abox, exp)
    end
    return new_abox
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
        s::Atomic => s
        e::Array => map(recursive_expand_concept, e)
    end
end

function change_premise(expression)
    @match expression begin
        [:subsumes, X, Y] => return [[:and, X, [:not, Y]], Object(string("_", next_var()))]
    end
    throw(ArgumentError("expression must contain the symbol :subsumes"))
end


function tableau_or(abox, aboxes)
    match_or = function(exp) @match exp begin
        [[:or, C, D], a::Object] =>  begin
                                        if !(C in abox) && !(D in abox)
                                          push!(aboxes, Set([collect(abox); [[D, a]]]))
                                          push!(abox, [C, a])
                                        end
                                      end
        end
    end
    for expression in abox
        match_or(expression)
    end
end

function tableau_and(abox)
    match_and = function(exp) @match exp begin
        [[:and, C, D], a::Object] =>  begin
                                        push!(abox, [C, a])
                                        push!(abox, [D, a])
                                      end
        # [:and, C, D] => begin
        #                     push!(abox, C)
        #                     push!(abox, D)
        #                 end
        _ => nothing
        end
    end

    for expression in abox
        match_and(expression)
    end
end

function tableau_universal(abox)

    condition_match = function(rule, Concept, obj::Object)
        for exp in abox
            @match exp begin
                [r, a, b::Object] =>    if r == rule && a == obj
                                            if !([Concept, b] in abox)
                                                push!(abox, [Concept, b])
                                            end
                                        end
                _ => nothing
            end
        end
    end

    match_universal = function(exp) @match exp begin
        [[:all, [:rule, r, C]], a::Object] =>  condition_match(r, C, a)
        _ => nothing
     end
    end

    for expression in abox
        match_universal(expression)
    end
end

function tableau_existential(abox)

    condition_match = function(rule, Concept, a_obj::Object)
        for exp in abox
            @match exp begin
                [r, a, c::Object] => if  r == rule && a == a_obj
                                        if [Concept, c] in abox return false end
                                     end
                _ => nothing
            end
        end

        # Otherwise add an object if one doesn't fit criteria
        b = Object(string("o", next_var()))  # New individual
        union!(abox, Set([
            [Concept, b],
            [rule, a_obj, b]
            ]))

        return true
    end

    match_existential = function(exp) @match exp begin
        [[:exists, [:rule, r, C]], a::Object] => condition_match(r, C, a)
        end
    end

    for expression in abox
        match_existential(expression)
    end
end

function printbox(abox)
    for item in abox
        print(item)
        print("\n")
    end
end


function tableau_rule(abox)
    tableau_and(abox)
    tableau_or(abox, aboxes)
    tableau_existential(abox)
    tableau_universal(abox)
    tableau_split_and(abox)
end

function tableau_rules(aboxes)
    for abox in aboxes
        tableau_rule(abox)
    end
end


function split_and(exp)
    expression_set = Set()

    function recur(exp)
            @match exp begin
                [:and, P, Q] => begin
                                 push!(expression_set, P)
                                 push!(expression_set, Q)
                                 recur(P)
                                 recur(Q)
                                end
                _       => nothing
            end

    end
    recur(exp)
    return expression_set
end

function tableau_split_and(abox)
    for exp in abox
        expression_set = split_and(exp)
        union!(abox, expression_set)
    end
end


function tableau(abox, tbox, premise)
    # Premise: Subsumption Question
    negated_premise = change_premise(premise)
    push!(abox, negated_premise)
    return tableau(abox, tbox)
end

function tableau(abox, tbox)
    abox = Set(expand_concepts(collect(abox), tbox))
    abox = nnf_abox(abox)
    aboxes = Set([abox])

    list_prev, list_curr = Set(), Set([nothing])
    unique = (boxes) -> Set(map(collect, collect(copy(boxes))))
    lengths = (boxes) -> Set([length(box) for box in boxes])
    count = 0
    while !isempty(setdiff(list_curr, list_prev)) && count < 20
        list_prev = unique(aboxes)
        tableau_rules(aboxes)
        list_curr =  unique(aboxes)

        # Force it to break, can't seem to figure out how to get set of set equality to work
        if isempty(setdiff(lengths(list_prev), lengths(list_curr)))
            count += 1
        else
            count = 0
        end

    end
    return aboxes
end

function is_consistent(abox)
    expression_set = copy(abox)
    for exp in abox
        union!(expression_set, split_and(exp))
    end
    for exp in abox
        contradiction = @match exp begin

            [[:all, [:rule, r, [:not, a]]], obj::Object] => [[:all, [:rule, r, a]], obj] in expression_set
            [[:all, [:rule, r, a]], obj::Object] => [[:all, [:rule, r, nnf([:not, a])]], obj] in expression_set

            [[:not, e], o::Object] => [e, o] in expression_set
            [e, o::Object]       => [nnf([:not, e]), o] in expression_set
            [:not, e] => e in expression_set
            e         => nnf([:not, e]) in expression_set
        end

        if contradiction return false end
    end
    return true
end


function abox_consistent(abox, tbox)
    aboxes = tableau(abox, tbox)
    aboxes = collect(aboxes)
    open_boxes = filter(is_consistent, aboxes)
    if length(open_boxes) == 0
        return false, nothing
    end
    return true, open_boxes[1]
end

# Check consistency of aboxes
function premise_subsumes(abox, tbox, premise)
    aboxes = tableau(abox, tbox, premise)
    box_open = any(map(is_consistent, collect(aboxes)))
    return aboxes, !box_open    # Unsatisfiable
end
