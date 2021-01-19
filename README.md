# Encoref

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://endremborza.github.io/Encoref.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://endremborza.github.io/Encoref.jl/dev)
[![Build Status](https://github.com/endremborza/Encoref.jl/workflows/CI/badge.svg)](https://github.com/endremborza/Encoref.jl/actions)
[![Coverage](https://codecov.io/gh/endremborza/Encoref.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/endremborza/Encoref.jl)

Entity coreference in julia

## The task

A coreference task is made up of a database pair:
- named entity reference set pairs
  - references to entities from two different databases organized to pairs that have the same *type* - so they have comparable attributes
  - these are essentially pairs of tables with matching column names and types
- a list of relation pairs
  - relationships from two databases that are organized to pairs

## Algorithm outline

### Space needs
- 2 entity reference space pairs
  - entity reference spaces are 2d arrays of indices, with a 1d array describing what types the indices in specific columns of the array belong to
  - a pair contains a space for both databases in the coreference task
  - 2 pairs are needed as some mutations require the space to transforming from one stage to the next
- 2 sorted joiner for each relationship pair, to make repeated lookups faster
- preparation space for matching
  - as one searches for matches in a pair of reference paths, this serves as a store for *best so far* matches
- latent variables of current matches
  - **TODO**

### Steps

- reset space pair with a sample from an entity type
  - can take sample with differing sample sizes on either side
- extend space pair using a relation pair
  - this requires the space of 2 space pairs to create
  - the space width increases
- organize the space pair to reflect the best matches
  - can only let the `top_n` matches to remain in the space
  - **WIP**
- integrate results from matching in a space pair to latent variables of current matches
  - **TODO**


the algorithm executes such steps until it reaches a state where either the established coreference resolution is satisfactory or it deems further steps useless


## Open questions

- how to determine the necessary steps
  - introducing some obvious rules, like no reset before integrating results
- how to reduce and/or calibrate the large number of parameters
- how to determine thresholds for establishing a coreference match, from the latent variables
- what happens if we run out of space during an extension step
