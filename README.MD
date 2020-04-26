# Description Logic Engine

## What this is

This is a description logic engine based on the **ALCQ language (ALC extended with number qualified restrictions)**. It is an implementation of the **Tableau** algorithm: provided an **ABOX** (assertions) and a **TBOX** (terminology definitions), the algorithm will determine satisfiability. It also can handle **Subsumption** questions (*"Is the PREMISE subsumed by the ABOX & TBOX?"*). 

## Syntax

### Code Syntax

This is written in Julia. Prefix syntax is used in the parsing, and Julia code is used to define the description logic statements. The engine has the following structures that can be used to define description logic statements (note the ":" is a julia symbol):


#### ALC Structs
- Concept
- Relation
- Object

#### Number Restrictions and Identity
- :>=
- :<=
- :!=

#### Subsumption
- :subsumes

#### Quantifiers
- :exists
- :all

#### Rule
- :rule 

#### First order logic
- :and 
- :not 
- :or  
- :implies 

#### Description Logic Statements
- EXPRESSION: is a list of ALC Structs, Number Restrictions, Subsumption, Quantifiers, Rules, & First Order Logic.
- ABOX: is a set of expressions
- TBOX: is a dicionary Dict mapping *Concepts => Expressions* 
- PREMISE: is an expression

### Example

```
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

# A TBox is a Dictionary (a mapping of Concepts to Definitions)
tbox = Dict(
    Woman => [:and,  Person, Female],
    Man =>   [:and,  Person, [:not, Female]],
    Mother => [:and, Woman,
                     [:exists, [:rule, hasChild, Person]]]
)

# An abox is a collection of logical expressions in Prefix notation
abox = [
    [hasChild, mary, tom],
    [Woman, mary],
    [Person, tom],
    [Mother, mary]
]
```


