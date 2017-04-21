---
layout: post
title: Working with Signals in Elm
draft: true
---

- initial configuration of signals
- Signal.foldp
- merging vs sampling (some signals, such as the arrow keys, need to be sampled as if they provided a continuous input, while others, such as the pause/unpause key, need to be taken into account every time they change)

Elm's signals provide an interface between the purely functional code composing the bulk of your application and the outside world. Figuring out how signals work was one of the harder parts of getting started with the language, so I thought I'd go over briefly how I used them in the Asteroids game I implemented.

# Pong signals

I was working from Elm's [Pong example][pong]. Its signals look like this:

```elm
-- SIGNALS

main =
  Signal.map2 view Window.dimensions gameState


gameState : Signal Game
gameState =
  Signal.foldp update defaultGame input


delta =
  Signal.map inSeconds (fps 35)


input : Signal Input
input =
  Signal.sampleOn delta <|
    Signal.map4 Input
      Keyboard.space
      (Signal.map .y Keyboard.wasd)
      (Signal.map .y Keyboard.arrows)
      delta
```

Let's take this one declaration at a time.

## main

The variations of Signal.map take a function and a signal of a value, and return a signal of the result of applying the function to that value. That means that whenever the gameState signal's value changes, `view` will be called again with the new value to re-render the page.

## gameState

Here, `Game` is a model of the Pong world, containing all the information needed to render the game -- the locations and velocities of the ball and players, plus a flag telling whether or not the game is paused.

`Signal.foldp` creates a "past-dependent signal". In this case, it applies the function `update` to `defaultGame` and `input` to create a new state. Whent the `input` signal changes, it will again apply `update` to the new state and the new input value to create another new state, and so on. It's essentially a game loop represented as a fold.

## delta

`delta` uses two functions from the Elm standard library's `Time` module to create a signal that delivers a new value 35 times per second (or as close to that as Elm can manage -- in this case, it should have no problem reaching 25 frames per second). The value that the signal delivers is the amount of time in seconds that has passed since the last value was delivered.

## input

Here's where all the different inputs necessary for Pong are combined into a data structure and wrapped in another signal. Inside out:
- `Keyboard.space`, `Keyboard.wasd` and `Keyboard.arrows` are signals of keyboard input defined by Elm's standard library. Space starts the game, while the wasd and arrow keys move the paddles. For the wasd and arrows signals, we're only interested in whether the players want to move their paddles up or down, so `Signal.map .y` extracts the y-axis values of those signals.
- `Signal.sampleOn` takes two signals, and delivers the value of the second each time the first changes. So for each new time delta returned by the `delta` signal, this signal delivers a new `Input` structure derived by combining the keyboard signals and the time delta itself (doing double duty here as both an input needed to calculate how far the ball and paddles have moved (as an argument to `Input`) as well as the signal controlling how often the input signal gets delivered (as the first argument to `Signal.sampleOn`).

# Asteroids signals

I was able to adapt the Pong signals pretty easily to an initial implementation of signals for Asteroids. It looked something like this:

```elm
main = Signal.map2 view Window.dimensions gameState


gameState : Signal Game
gameState = Signal.foldp update newGame input


delta = Signal.map Time.inSeconds (Time.fps 35)


input : Signal Input
input =
  Signal.sampleOn delta <|
    Signal.map4 Input
      Keyboard.enter
      Keyboard.space
      Keyboard.arrows
      delta
```

This is nearly identical to the Pong implementation, except I care about a slightly different set of keyboard inputs. Instead of starting the game, the space key fires shots. The enter key starts the game in its place.

This worked initially, but I ran into two interesting roadblocks when I tried to add features to the game. The first was the ability to pause and unpause. At first, I tried simply checking the state of the enter key when updating the game for each frame, and switching the state from `Play` to `Pause` or vice versa if the key was pressed. That sort of worked, but had a serious usability issue: the game state updates 35 times per second, and a human pressing the enter key usually presses it for a longer time than 1/35th of a second. That means that when a player tries to pause the game by pressing the enter key, the game state will flipped not once but some larger number of times. If the enter key is pressed for an even number of frames, the game will hiccup a bit but continue as before, since it will end up in the same play or pause state that it started in. If the key is pressed for an odd number of frames, the state will change to the desired result, but still with undesirable hiccuping. The upshot is pressing the enter key would change the game state basically at random.

What I really wanted instead of reading the state of the enter key in every game frame was to react every time the state of the enter key changes -- in other words, I wanted to listen to `Keyboard.enter` as a separate signal.
[pong]: http://elm-lang.org/examples/pong
