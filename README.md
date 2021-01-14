# Encoref

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://endremborza.github.io/Encoref.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://endremborza.github.io/Encoref.jl/dev)
[![Build Status](https://github.com/endremborza/Encoref.jl/workflows/CI/badge.svg)](https://github.com/endremborza/Encoref.jl/actions)
[![Coverage](https://codecov.io/gh/endremborza/Encoref.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/endremborza/Encoref.jl)

Entity coreference in julia

## The task

A coreference task is made up of:
- named entity reference set pairs
  - references to entities from two different databases organized to pairs that have the same *type* - so they have comparable attributes
  - these are essentially pairs of tables with matching column names and types
- a list of relation pairs
  - relationships from two databases that are organized to pairs

## Algorithm outline

- determinants of a roll:
  - a chain of relation pairs, with directions
  - parameters for rolling - `left_subset`, `right_subset`, `top_n`, ...

- one roll:
  - the algorithm takes an entity reference set pair - possibly takes subsets of one or both sides - from the root of the relation pair chain
  - creates matches using simple fuzzy matching
  - takes the `top_n` best matches
  - creates a path pair using the next relation pair in the chain
  - matches the paths based on similarities among the entity references making up the paths
    - this, just like the initial fuzzy matching utilizes the information whether some references have been established to be coreferent before
  - iterates the process - with longer paths in the pairs - until it reaches the end of the relation pair chain of the roll - or runs out of memory
  - stores the best matches and uses them to create established coreferences

the algorithm executes such rolls until it reaches a state where either the established coreference resolution is satisfactory or it deems further rolls useless


## Open questions

- how to determine the necessary rolls
- how to reduce and/or calibrate the large number of parameters
- how to determine thresholds for establishing a coreference match

