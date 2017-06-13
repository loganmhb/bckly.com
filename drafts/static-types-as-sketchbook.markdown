---
title: Sketching with static types
date: ???
---

Classic view on static vs dynamic typing -- dynamic typing easier for
prototyping, static typing good for correctness & guarantees

But having spent a couple weeks now working on a substantial project in Rust, one of the things I've noticed is the way the powerful type system empowers me to write the code I want first, then refactor it until it works. In a dynamic language like Clojure, you'd quickly get into a mess of mismatched datatypes and unexpected errors, but in a language like Rust the type system frees me from a lot of those worries. The process of programming feels more fluid precisely because the rigid type system acts as a string I can follow back towards a correct program.

Static vs dynamic typing isn't a question that has a right answer, but this is an angle I hadn't considered before.