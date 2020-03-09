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


# Negation Normal Form
@test nnf(not_and) == not_and_nnf
@test nnf(not_or) == not_or_nnf
@test nnf(not_not) == not_not_nnf
@test nnf(exists_rule) == exists_rule_nnf
@test nnf(all_rule) == all_rule_nnf

query = [:and, [:and, [:and, [:A, :B], [:or, :C, :D]], [:E, :F]], :G]

@test split_and(query) == Set([
[:E, :F],
:G,
[:and, [:and, [:A, :B], [:or, :C, :D]], [:E, :F]],
[:or, :C, :D],
[:A, :B],
[:and, [:A, :B], [:or, :C, :D]]
])


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
    [Mother, mary],
]

expansion = expand_concepts(abox, tbox)
@test expansion == [[hasChild, mary, tom]]

expansion = expand_concepts(abox2, tbox)
answer = [[[:and,  [:and,  Person, Female],
[:exists, [:rule, hasChild, Person]]], mary]]

@test expansion == answer

abox = [
    [[:<=, 3, hasChild, :T], mary]
]


expansion = expand_concepts(abox, Dict())
@test expansion == [[[:<=, 3, hasChild, [:or, T, [:not, T]]], mary]]

premise = [:subsumes, Mother, Woman]
@test change_premise(premise) ==  [[:and, Mother, [:not, Woman]], Object("_1")]



abox = Set([
        [[:and, Person, Female], mary]
    ])


and_result = Set([
        [[:and, Person, Female], mary],
        [Person, mary],
        [Female, mary]
    ])


tableau_and(abox)
@test abox == and_result

abox = Set([
    [[:or, Person, Female], mary]
])

aboxes = Set([
    #Abox
    abox
])

or_result = Set([
    #Abox
    Set([
        [[:or, Person, Female], mary],
        [Person, mary],
    ]),
    Set([
        [[:or, Person, Female], mary],
        [Female, mary],
    ]),
])



tableau_or(abox, aboxes)
@test aboxes == or_result


abox = Set([
    [[:or, Person, Female], mary],
    [Female, mary]
])

aboxes = Set([
    #Abox
    abox
])

aboxes_copy = Set([
    Set(collect(abox))
])

tableau_or(abox, aboxes)
@test aboxes == aboxes_copy


# Existential Test E-rule

abox = Set([
    [[:exists, [:rule, hasChild, Man]], mary]
])

obj = Object("o2")
new_abox = Set([
    [[:exists, [:rule, hasChild, Man]], mary],
    [hasChild, mary, obj],
    [Man, obj]
])


tableau_existential(abox)
@test abox == new_abox

abox = Set([
    [[:exists, [:rule, hasChild, Man]], mary],
    [hasChild, mary, tom],
    [hasChild, mary, obj],
    [Man, obj]
])

abox_copy = copy(abox)

tableau_existential(abox)
@test abox == abox_copy

abox = Set([
    [[:exists, [:rule, hasChild, Man]], mary],
    [r_eats, mary, tom],
    [hasChild, mary, Q],
    [Man, P]
])

abox_copy = copy(abox)
obj = Object("o3")
push!(abox_copy, [Man, obj])
push!(abox_copy, [hasChild, mary, obj])

tableau_existential(abox)
@test abox == abox_copy

# Universal Test
abox = Set([
    [[:all, [:rule, r_eats, Person]], mary],
    [r_eats, mary, tom]
])

abox_copy = copy(abox)
push!(abox_copy, [Person, tom])

tableau_universal(abox)
@test abox == abox_copy

abox = Set([
    [[:all, [:rule, hasChild, Person]], mary],
    [r_eats, mary, tom]
])

abox_copy = copy(abox)
tableau_universal(abox)
@test abox == abox_copy

# consistency
abox = Set([
    [:not, [Mother, mary]],
    [Mother, mary]
])

@test is_consistent(abox) == false

abox = Set([
    [:not, [Mother, mary]],
    [r_eats, mary, tom]
])

@test is_consistent(abox) == true




# subsumes
tbox = Dict(
    Woman => [:and,  Person, Female],
    Man =>   [:and,  Person, [:not, Female]],
    Mother => [:and, Woman,
                     [:exists, [:rule, hasChild, Person]]]
)

abox = Set([
    [:or, [Person, mary], [Person, tom]]
])

premise = [:subsumes, Person,  Female]
aboxes = tableau(abox, tbox, premise)
solution = Set([
    # Abox
    Set([
        Any[Any[:not, Female], Object("_4")],
        Any[:or, [Person, mary], [Person, tom]],
        Any[Person, Object("_4")],
        Any[Any[:and, Person, Any[:not, Female]], Object("_4")],
    ])
])

@test aboxes == solution

# check premise is correctly identified in subsumption

GoodStudent = Concept("Good Student")
Smart = Concept("Smart")
Studious = Concept("Studious")
attendedBy = Relation("Attended by")
SmartPerson = Concept("Smart Person")

tbox = Dict(
    GoodStudent => [:or,  Smart, Studious],
    SmartPerson => Smart
)

premise2 = [:subsumes, [:and, [:exists, [:rule, attendedBy, Smart]],
                             [:exists, [:rule, attendedBy, Studious]]],
                      [:exists, [:rule, attendedBy, GoodStudent]]]

premise = [:subsumes, [:exists, [:rule, attendedBy, [:and, Smart, Studious]]],
                      [:exists, [:rule, attendedBy, GoodStudent]]]


# Is person a subset of woman
aboxes, answer = premise_subsumes(Set(), tbox, premise)
@test answer == true

aboxes, answer = premise_subsumes(Set(), tbox, premise2)
@test answer == true

# Abox consistent
abox = Set([
    [Person, mary],
    [:not, [Person, mary]]
])
tbox = Dict()

@test abox_consistent(abox, tbox)[1] == false

abox = Set([
    [Person, mary],
    [:not, [Mother, mary]]
])
tbox = Dict()
@test abox_consistent(abox, tbox)[1] == true


tbox = Dict(
    Woman => [:and,  Person, Female]
)
abox = Set([
    [Woman, mary],
    [:not, [Person, mary]]
])

@test abox_consistent(abox, tbox)[1] == false

print()
