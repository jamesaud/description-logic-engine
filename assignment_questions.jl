using Test
include("logic_conversion.jl")


# Define Concepts and Relations and Objects
hasChild = Relation("has child")

Person = Concept("Person")
Female = Concept("Female")
Woman = Concept("Woman")
Man = Concept("Man")
Mother = Concept("Mother")

mary = Object("mary")
tom = Object("tom")

# A T-Box is a Dictionary (a mapping of Concepts to Definitions)
tbox = Dict(
    Woman => [:and,  Person, Female],
    Man =>   [:and,  Person, [:not, Female]],
    Mother => [:and, Woman,
                     [:exists, [:rule, hasChild, Person]]]
)

# 1. An abox is a collection of logical expressions in Prefix notation
abox = [
    [hasChild, mary, tom],
    [Woman, mary],
    [Person, tom],
    [Mother, mary]
]

result =  Set([
    Any[Concept("Female"), Object("mary")],
    Any[Any[:and, Any[:and, Concept("Person"), Concept("Female")], Any[:exists, Any[:rule, Relation("has child"), Concept("Person")]]], Object("mary")],
    Any[Any[:exists, Any[:rule, Relation("has child"), Concept("Person")]], Object("mary")],
    Any[Relation("has child"), Object("mary"), Object("tom")],
    Any[Concept("Person"), Object("tom")],
    Any[Concept("Person"), Object("mary")],
    Any[Any[:and, Concept("Person"), Concept("Female")], Object("mary")]
    ])

consistent, model = abox_consistent(abox, tbox)

@test consistent == true
@test model == result


# 2. Subsumption

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


# 3. Prove the following

r = Relation("r")
s = Relation("s")
A = Concept("A")
B = Concept("B")
C = Concept("C")

#∀r.∀s.A ⊓ ∃r.∀s.B ⊓ ∀r.∃s.C ⊑ ∃r.∃s.(A⊓B⊓C)

one = [:all, [:rule, r, [:all, [:rule, s, A]]]]
two = [:exists, [:rule, r, [:all, [:rule, s, B]]]]
three = [:all, [:rule, r, [:exists, [:rule, s, C]]]]
four = [:exists, [:rule, r, [:exists, [:rule, s,  [:and, A, [:and, B, C]]]]]]

premise = [:subsumes, [:and, [:and, one, two], three], four]

aboxes, answer = premise_subsumes(Set(), Dict(), premise)

@test answer == true


# ∀r.∀s.A ⊓ (∃r.∀s.¬A ⊔ ∀r.∃s.B) ⊑ ∀r.∃s.(A ⊓ B) ⊔ ∃r.∀s.¬B
one = [:all, [:rule, r, [:all, [:rule, s, A]]]]
two = [:exists, [:rule, r, [:all, [:rule, s, [:not, A]]]]]
three = [:all, [:rule, r, [:exists, [:rule, s, B]]]]
four = [:all, [:rule, r, [:exists, [:rule, s, [:and, A, B]]]]]
five = [:exists, [:rule, r, [:all, [:rule, s, [:not, B]]]]]

premise = [:subsumes, [:and, one, [:or, two, three]], [:or, four, five]]

aboxes, answer = premise_subsumes(Set(), Dict(), premise)

@test answer == false


# 4. Numbers

joe = Object("joe")
ann = Object("ann")
eva = Object("eva")
mary = Object("mary")

# Assuming that the names are unique objects
abox = Set([
    [hasChild, mary, ann],
    [hasChild, mary, eva],
    [hasChild, mary, joe],
    [[:<=, 2, [:rule, hasChild, :T]], mary],
])

consistent, box = abox_consistent_with_obj_and_t(abox)
@test consistent == false


# Assuming thhat the names are not unique objects
abox = Set([
    [hasChild, mary, ann],
    [hasChild, mary, eva],
    [hasChild, mary, joe],
    [[:<=, 2, [:rule, hasChild, :T]], mary],
])

consistent, boxes = abox_consistent_with_t(abox)
result = Set([
    [Relation("has child"), Object("mary"), Object("joe")],
    [[:or, Concept("T"), [:not, Concept("T")]], Object("ann")],
    [Concept("T"), Object("mary")],
    [[:or, Concept("T"), [:not, Concept("T")]], Object("joe")],
    [Concept("T"), Object("joe")],
    [[:<=, 2, [:rule, Relation("has child"), [:or, Concept("T"), [:not, Concept("T")]]]], Object("mary")],
    [Concept("T"), Object("ann")],
    [Relation("has child"), Object("mary"), Object("ann")],
    [[:or, Concept("T"), [:not, Concept("T")]], Object("mary")]
])

@test consistent = true
@test boxes[1] == result