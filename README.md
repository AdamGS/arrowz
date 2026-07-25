# Arrowz

arrowz is a minimal implementation of the [Apache Arrow](https://arrow.apache.org/) in-memory columnar format, with an ultimate goal of being able to actually pass data to/from other established implementations.

Its intended as an exercise to learn zig and spend more time doing lower-level code. I'm trying to implement it mostly
from the spec, which so far has been great, and with ~0 LLM assistance.

I have no real sense as to how idiomatic the API is, and I suspect it'll keep changing as I read more of Zig's standard library.

## Development

The two tools I currently use are zig 0.16 and [`just`](https://github.com/casey/just).

## TODO

1. Replace `Aligned` usage with internal aligned buffer type
1. Cheap buffer slicing and indexing, maybe that's some wrapper around the array types, or like in arrow-rs - at the buffer level.
1. Create builders for everything? Mostly useful if we do data sharing so splitting mutability might make sense? IDK if that's even possible in Zig.
