# HotFuzz

![Hot Fuzz](static/fence.gif)

Provides a simple tracer for Julia code, based on plans for world domination me and @carnaval came up with while high at JuliaCon 2015. No guarantees of code reliability, correctness, fitness for a given purpose or even basic coherence are provided.

```julia
import HotFuzz: trace!, runtrace

trace!(@which(gcd(1, 1))) # Enable tracing of a method
runtrace(gcd, rand(0:100), rand(0:100)) # Trace a call of the function
```

`runtrace` returns a tuple `(result, trace)`. `trace` is an array of tuples `(Branch, Bool)`; each `Branch` represents a `gotounless` in a given source code location, and the bool tells you whether the `goto` ran.

The original idea was for this to be used as a heuristic for guiding fuzz testing in the vein of American Fuzzy Lop. I also think it could be used to generate a set of test cases for a function without needing an invariant. However, it needs more in the way of heuristics for interesting traces, data generation and mutation etc.
