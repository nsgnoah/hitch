# Fifty more chains

## Choice

Add 50 chains to `Hitch/Resources/chains.json`, taking it from 100 to 150.

## Why

`PuzzleBook.puzzle(_:)` picks chain `(n - 1) % chains.count`. With 100 chains, No. 101 (December 10, 2026) repeats No. 1, and players who've been there since launch would start seeing chains they've already solved. The README already flags this ("unless more are added"). More puzzles is the most player-visible thing that can be done and checked without a Mac: SwiftUI changes can't be built or run on Linux.

With 150 chains, No. 151 (January 29, 2027) is the first repeat.

## How

- The new chains go only at the end, so chains 1–100 keep their indices and no saved record changes. (Records store the words, so a reordered file would quietly reset progress.)
- Same rules as the existing set: seven words of capital letters, every neighboring pair a common compound word or phrase, no word repeated inside a chain, no chain repeated in the file.
- No. 101 is SNOW BALL ROOM SERVICE STATION WAGON WHEEL, the fallback chain in `PuzzleBook.swift`, which until now could only show up if `chains.json` failed to load.

## Timing

A device running a build with only 100 chains will show No. 1's chain again for No. 101. If that player then updates, their No. 101 record won't match the new chain and that puzzle starts over. To avoid this, the build that carries these chains needs to be live before December 10, 2026.
