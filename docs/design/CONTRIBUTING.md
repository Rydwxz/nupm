# Contributing to nupm

In a more complete state, nupm can serve as an important meta-layer and second point of contact of each user's relationship with extending and configuring their nu experience. Code written for the purpose of personal integration should feel very natural in nushell's rich interative environment, so it should be written in whatever style the user prefers.
Code written to be contributed to nupm, however, should strive to be as simple and direct as possible. It may be the first and/or last officially released non-tutorial code the user looks at, so we want to set a good example.

** ideas for guidelines
* -- pipelines longer than two or three are always line-broken
```
let n = seq 0 5
    | shuffle
    | zip (seq 6 11)
    | each {|pair| $pair.0 * $pair.1 }
    | sum
```
* -- avoid abbreviations and other short, difficult to differentiate names (above, see `pair` in the closure rather than `p`)
* -- prefer shadowing and iterative combinators over mutability
