using Test
include("logic_conversion.jl")


r = Relation("r")
s = Relation("s")

A = Concept("A")
B = Concept("B")
C = Concept("C")
Boy = Concept("Boy")

hasChild = Relation("has child")
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
printbox(a_box)
