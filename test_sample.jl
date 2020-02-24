using Test
include("logic_conversion.jl")


#∀r.∀s.A ⊓ ∃r.∀s.B ⊓ ∀r.∃s.C ⊑ ∃r.∃s.(A⊓B⊓C)

r = Relation("r")
s = Relation("s")
A = Concept("A")
B = Concept("B")
C = Concept("C")

one = [:all, [:rule, r, [:all, [:rule, s, A]]]]
two = [:exists, [:rule, r, [:all, [:rule, s, B]]]]
three = [:all, [:rule, r, [:exists, [:rule, s, C]]]]
four = [:exists, [:rule, r, [:exists, [:rule, s,  [:and, A, [:and, B, C]]]]]]

premise = [:subsumes, [:and, [:and, one, two], three], four]

aboxes, answer = premise_subsumes(Set(), Dict(), premise)




premise = [:subsumes, [:all, [:rule, r, A]],
                      [:exists, [:rule, r, A]]]

aboxes, answer = premise_subsumes(Set(), Dict(), premise)
@test answer == true




premise = [:subsumes, [:and, [:all, [:rule, r, [:all, [:rule, s, A]]]],
                               [:exists, [:rule, r, [:all, [:rule, s, B]]]]],
                      [:exists, [:rule, r, [:exists, [:rule, s, [:and, A, B]]]]]]


premise = change_premise(premise)
@test premise == [[:and, [:and, [:all, [:rule, r, [:all, [:rule, s, A]]]],
                               [:exists, [:rule, r, [:all, [:rule, s, B]]]]],
                        [:not, [:exists, [:rule, r, [:exists, [:rule, s, [:and, A, B]]]]]]],  Object("_5")]

abox = Set([premise])
abox = nnf_abox(abox)

tableau_and(abox)

e = [[:all, [:rule, r, [:all, [:rule, s, [:or,  [:not, A], [:not, B]]]]]],  Object("_5")]
@test e in abox
printbox(abox)

# statement = [:subsumes, [:and, [:all, [:rule, r, A]],
#                                [:exists, [:rule, r, B]]],
#                     [:exists, [:rule, r, [:and, A, B]]]]
#

aboxes, answer = premise_subsumes(Set(), Dict(), statement)
print()
