using Test
include("logic_conversion.jl")


r = Relation("r")
s = Relation("s")

A = Concept("A")
B = Concept("B")
C = Concept("C")
Boy = Concept("Boy")
Male = Concept("Male")

hasChild = Relation("has child")
brother = Relation("brother")
mary = Object("Mary")
tom = Object("Tom")
mark = Object("Mark")


premise = [[:<=, 3, [:rule, r, hasChild]], mary]

abox = Set([
    [:<=, 3, [:rule, hasChild, Boy]],
    [:not, [:>=, 5, [:rule, hasChild, Boy]]],
    [:not, [:<=, 1, [:rule, hasChild, Boy]]]
])


res = number_rules_nnf(abox)
@test [:<=, 3, [:rule, hasChild, Boy]] in res
@test [:<=, 4, [:rule, hasChild, Boy]] in res
@test [:>=, 2, [:rule, hasChild, Boy]] in res

abox = Set([
    [:not, [:>=, 0, [:rule, hasChild, Boy]]],
])

@test_throws InvalidFormula number_rules_nnf(abox)



abox = Set([
    [[:>=, 3, [:rule, hasChild, Boy]], mary],
])

a_box = copy(abox)
a = [Boy, Object("o1")]
b = [Boy, Object("o2")]
c = [Boy, Object("o3")]
d = [Boy, Object("o4")]
tableau_gt(a_box)
@test a in a_box
@test b in a_box
@test c in a_box
@test !(d in a_box)


abox = Set([
    [[:>=, 3, [:rule, hasChild, Boy]], mary],
    [hasChild, mary, tom],
    [hasChild, mary, mark],
    [Boy, mark],
    # [:<=, mary, tom],
    # [:<=, mary, mark],
    # [:<=, mark, mary],
    # [:<=, mark, tom],
    # [:<=, tom, mary],
    # [:<=, tom, mark]
])

a_box = copy(abox)
tableau_gt(a_box)
a = [Boy, Object("o4")]
b = [Boy, Object("o5")]
c = [Boy, Object("o6")]
@test a in a_box
@test b in a_box
@test !(c in a_box)


abox = Set([
    [hasChild, mary, mark],
    [hasChild, mary, tom],
    [:and, [hasChild, mary, mark], [brother,  tom, mark]],
    ]
)

o4 = Object("o4")
lt_replace_object_in_abox(mark, o4, abox) # Replace mark with o1

res = Set([
    [hasChild, mary, o4],
    [hasChild, mary, tom],
    [:and, [hasChild, mary, o4], [brother,  tom, o4]],
    ]
)

@test abox == res


abox = Set([
    [hasChild, mary, mark],
    [:and, [hasChild, mary, mark], [hasChild,  mary, mark]],
    ]
)

add_object_inequality(abox)

@test [:!=, mary, mark] in abox
@test [:!=, mark, mary] in abox

o1, o2, o3, o4 = Object("o1"), Object("o2"), Object("o3"), Object("o4")

abox = Set([
    [[:<=, 2, [:rule, hasChild, Male]], mary],
    [hasChild, mary, o1],
    [hasChild, mary, o2],
    [hasChild, mary, o3],
    [hasChild, mary, o4],
    [Male, o1],
    [Male, o2],
    [Male, o3],
    [Male, o4],
    [:!=, o1, o2],
    [:!=, o2, o1]
    ])

tableau_lt(abox)
print()
