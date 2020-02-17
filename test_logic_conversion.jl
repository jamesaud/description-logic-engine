using Test
include("logic_conversion.jl")

P = Object("P")
Q = Object("Q")

c_person = Concept("person")
c_junkFood = Concept("junk food")
c_water = Concept("water")

r_eats = Relation("eats")
r_drinks = Relation("Drinks")

not_and = [:not, [:and, P, Q]]
not_and_nnf = [:or, [:not, P], [:not, Q]]

not_or = [:not, [:or, P, Q]]
not_or_nnf = [:and, [:not, P], [:not, Q]]

not_not = [:not, [:not, P]]
not_not_nnf = P

exists_rule = [:not, [:exists, [:rule, r_eats, c_person]]]
exists_rule_nnf = [:all, [:rule, r_eats, [:not, c_person]]]  

all_rule = [:not, [:all, [:rule, r_eats, c_person]]]
all_rule_nnf = [:exists, [:rule, r_eats, [:not, c_person]]]

apply = [:apply, [:not, [:and, [:rule, r_eats, c_junkFood],
                               [:rule, r_drinks, c_water]]], P]

apply_nnf = [:apply, [:or, [:not, [:rule, r_eats, c_junkFood]],
                           [:not, [:rule, r_drinks, c_water]]], P]

# Negation Normal Form
@test nnf(not_and) == not_and_nnf
@test nnf(not_or) == not_or_nnf
@test nnf(not_not) == not_not_nnf
@test nnf(exists_rule) == exists_rule_nnf
@test nnf(all_rule) == all_rule_nnf
@test nnf(apply) == apply_nnf


hasChild = Relation("has child")
Person = Concept("Person")
Female = Concept("Female")
Woman = Concept("Woman")
Man = Concept("Man")
Mother = Concept("Mother")

mary = Object("mary")
tom = Object("tom")

tbox = Dict(
    Woman => [:and,  Person, Female],
    Man =>   [:and,  Person, [:not, Female]],
    Mother => [:and, Woman, 
                     [:exists, [:rule, hasChild, Person]]]
)

abox = [
    [hasChild, mary, tom]
]

abox2 = [
    [:apply, Mother, mary],
]

expansion = expand_concepts(abox, tbox)
@test expansion == [[hasChild, mary, tom]]

expansion = expand_concepts(abox2, tbox)
answer = [[:apply, [:and,  [:and,  Person, Female], 
[:exists, [:rule, hasChild, Person]]], mary]]

@test expansion == answer


premise = [:subsumes, Mother, Woman]
@test change_premise(premise) ==  [:apply, [:and, Mother, [:not, Woman]], Object("_a")]


tableau(abox2, tbox, premise)