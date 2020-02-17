include("logic_conversion.jl")

### Examples ###
woman = Concept("Woman")
mother = Concept("Mother")
person = Concept("Person")
female = Concept("Female")
junkFood = Concept("JunkFood")
student = Concept("Student")
womanWithManyChildren = Concept("Woman with many children")

hasChild = Relation("hasChild")
eats = Relation("eats")

mary = Object("mary")
peter = Object("peter")

# Tbox #
t1 = [:is, woman, [:and, person, female]]
t2 = [:is, mother, [:and, [:and, person, female],
                    [:exists, [:rule, hasChild, person]]]]

t3 = [:is, womanWithManyChildren, [:>, :3, hasChild]] # always has an operator: =, >, <


# Abox
a1 = [mother, mary]          # Concept Assertion
a2 = [hasChild, mary, peter] # Role Assertion
a3 = [:not, [:all, [:rule, eats, junkFood, peter]]] # Rule
a4 = [:subsumes, student, [:rule, eats, junkFood]]
a5 = [:apply, [:and, [:exists, [:rule, :attendBy, :smart]], 
                     [:exists, [:rule, :attendedBy, :studious]]], :A]
