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

Atomic = Union{Relation, Concept, Object, Symbol, Integer}
Expression = Union{Array{Atomic}, Atomic}
Tbox = Dict{Concept, Atomic}
Abox = Array{Expression}

# Tautology concept
T = Concept("T")
Tautology = [:or, T, [:not, T]]
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

    if expression == :T
        expression = Tautology
    end

    return @match expression begin
        e::Array => map(recursive_expand_concept, e)
        s => s
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
                                          newbox = copy(abox)
                                          push!(newbox, [D, a])
                                          push!(aboxes, newbox)
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

struct InvalidFormula <: Exception
    formula
end

function number_rule_nnf(exp)
    recur(expr) = @match expr begin
            [:not, [:>=, 0, [:rule, r, C]]] => throw(InvalidFormula(expr))
            [:not, [:>=, n, [:rule, r, C]]] => [:<=, n - 1, recur([:rule, r, C])]
            [:not, [:<=, n, [:rule, r, C]]] => [:>=, n + 1, recur([:rule, r, C])]
            e::Array => map(recur, e)
            e        => e
        end
    return recur(exp)
end

function number_rules_nnf(abox)
    abox = map(number_rule_nnf, collect(abox))
    return Set(abox)
end


function count_occurences_gt_rule(rule, object, Concept, abox)
    count = 0

    # Get all occurences of objects and return them
    objects = []
    for exp in abox
        @match exp begin
            [r, a, c] => if r == rule && a == object  && [Concept, c] in abox
                            count += 1
                            push!(objects, c)
                         end
        end
    end
    return count, objects
end

function tableau_gt(abox)
    for exp in abox
        @match exp begin
            [[:>=, n, [:rule, r, C]], a] => begin
                                                occurences, objects = count_occurences_gt_rule(r, a, C, abox)
                                                for i = occurences:n-1
                                                    b = Object(string("o", next_var()))
                                                    push!(objects, b)
                                                    push!(abox, [r, a, b])
                                                    push!(abox, [C, b])
                                                end
                                                for ob1 in objects
                                                    for ob2 in objects
                                                        if ob1 != ob2
                                                            push!(abox, [:!=, ob1, ob2])
                                                        end
                                                    end
                                                end
                                            end
        end
    end
    return abox
end


function add_object_inequality(abox)
    objects = Set()
    recur(expr) = @match expr begin
        e::Object => push!(objects, e)
        e::Array => map(recur, expr)
        e => e
    end
    for e in abox
        recur(e)
    end

    for o1 in objects
        for o2 in objects
            if o1 != o2
                push!(abox, [:!=, o1, o2])
            end
        end
    end
end


function lt_replace_object_in_abox(o1, o2, abox)
    # replace o1 with o2
    recur(expr) = @match expr begin
         e::Object  =>  e == o1 ? o2 : e
         e::Array   =>  map(recur, e)
         e          =>  e
    end

    for exp in abox
        e = recur(exp)
        delete!(abox, exp)
        push!(abox, e)
    end
end

function lt_rule(n, r, C, a, abox)
    objects = Set()
    for exp in abox
        @match exp begin
            [r_, a_, b] => if r == r_ && a_ == a
                            if [C, b] in abox
                                push!(objects, b)
                            end
                           end
        end
    end

    if length(objects) <= n
        return
    end

    replacements = Dict()
    for o1 in objects
        inequality_missing = [o2 for o2 in objects if !([:!=, o1, o2] in abox) && o1 != o2]
        replacements[o1] = Set(inequality_missing)
    end

    replaced = Dict()
    for (o1, objects) in replacements
        valid_obs = objects
        println(o1)
        println(valid_obs)
        for ob in objects
            s = copy(replacements[ob])
            push!(s, ob)
            intersect!(valid_obs, s)
        end
        println(valid_obs)
        println()

        for o2 in valid_obs
            lt_replace_object_in_abox(o1, o2, abox)         # replace o2 with o1
            replaced[o2] = o1
        end
    end
    printbox(abox)
end

function tableau_lt(abox)
    for exp in abox
        @match exp begin
            [[:<=, n, [:rule, r, C]], a] => lt_rule(n, r, C, a, abox)
        end
    end
end

function tableau_choose_rule(abox, aboxes)
    apply_rule(r, a, C) = @match exp begin
        [:rule, r_, a_, b_] => if r_ == r && a_ == a
                                if !([C, b] in abox) && !(nnf([:not, [C, b]]) in abox)
                                    newbox = copy(abox)
                                    push!(abox, [C, b])
                                    push!(newbox, nnf([:not, [C, b]]))
                                    push!(aboxes, newbox)
                                end
                            end
         e => e
    end


    for exp in abox
        @match exp begin
            [[:<=, n, [:rule, r, C]], a] => begin
                                                apply_rule(r, a, C)
                                            end
        end
    end
    return abox
end


function tableau_number_rules(aboxes)
    for abox in aboxes
        tableau_choose_rule(abox, aboxes)
        tableau_gt(abox)
        tableau_lt(abox)
    end
end

function tableau_rules(aboxes)
    tableau_number_rules(aboxes)
    for abox in aboxes
        tableau_and(abox)
        tableau_or(abox, aboxes)
        tableau_existential(abox)
        tableau_universal(abox)
        tableau_split_and(abox)
    end
    return aboxes
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
    lengths = (boxes) -> Set([length(box) for box in copy(boxes)])
    count = 0

    while !isempty(setdiff(list_curr, list_prev)) && count < 40
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
    ab = Set()
    # Fix a bug where bad box keeps getting generated
    for abox in aboxes
        if is_consistent(abox)
            tableau_or(abox, aboxes)
        end
        push!(ab, abox)
    end

    return ab
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
