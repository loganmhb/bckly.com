---
layout: post
title: Working with Signals in Elm
draft: true
---

- initial configuration of signals
- Signal.foldp
- merging vs sampling (some signals, such as the arrow keys, need to be sampled as if they provided a continuous input, while others, such as the pause/unpause key, need to be taken into account every time they change)

In Elm, Signals provide an interface between the purely functional code you write and the outside world.
