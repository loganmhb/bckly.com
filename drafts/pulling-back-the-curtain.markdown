---
title: Pulling Back the Curtain
date: 2017-07-07
---

I've written a little bit about the capture-the-flag (CTF) challenge
I've been working on at RC. Last week I completed the final level.

All of the levels were fun in their own ways, but the ones involving
low-level exploits of classic C vulnerabilities -- out-of-bounds array
accesses and stack buffer overflows -- taught me the most about how my
computer actually works. And boy, is it a miracle that it works at
all, let alone connects on a regular basis to millions of other
computers that also mostly work how they're supposed to.

Working with C -- and learning how to go past C to the assembly
language and machine code that the computer actually executes

examining memory: strings, integers, pointers are all exposed as
simply bytes, as they have been all along.

the nature of things is revealed: the machine's nature as a machine;
the fragility of the system; nothing prevents you from overwriting the
stack, but most of the information necessary for your program to
continue is stored on the stack

In the end it is remarkable how much programming langauges succeed in
hiding from us. Any resemblance to mathematics, in programming, is the
result of a lot of hard work and illusioneering. The computer in its
naked state bears closer resemblance to a typewriter than to an
equation.