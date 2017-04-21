---

Looking over some of the games implemented in the examples, I decided an Asteroids clone would be a reasonable first project. It'd be complex enough to get a feel for the language without being too hard to render or involving too many entities to keep track of. Since I use Clojure for my day job and have a little bit of experience with Haskell, I wasn't too worried about the Elm learning curve -- I mostly expected to have to get my head around functional reactive programming and the Elm Architecture. I used the [Pong example](http://elm-lang.org/examples/pong) as a model. You can see the results [here](/asteroids/).

Elm's syntax is heavily Haskell-inspired, but using the two feels worlds apart. Elm is just incredibly user-friendly, especially where it counts most: error messages. This is something that Clojure regularly fails to handle well, and it's really refreshing to see error messages handled with care and empathy.

For example, suppose you're working with the Pong example above, and you've accidentally left out some parentheses while defining the time delta signal:

{% highlight elm %}

-- this is a comment
delta =
Signal.map inSeconds fps 35 -- should be `Signal.map inSeconds (fps 35)`

{% endhighlight %}

Elm gives the following compilation error:

TYPE MISMATCH
The 2nd argument to function `map` is causing a mismatch.

213|   Signal.map inSeconds fps 35
Function `map` is expecting the 2nd argument to be:

Signal Time

But it is:

number -> Signal Time

Hint: I always figure out the type of arguments from left to right. If an
argument is acceptable when I check it, I assume it is "correct" in subsequent
checks. So the problem may actually be in how previous arguments interact with
the 2nd.


TYPE MISMATCH
Function `map` is expecting 2 arguments, but was given 3.

213|   Signal.map inSeconds fps 35
Maybe you forgot some parentheses? Or a comma?

Not only does it tell you exactly what the mismatch was between what the compiler was expecting and what it found, it suggests some common causes (including the correct one, in this case). The attention to detail in how the error is spaced out and formatted makes it easy for an experienced progammer to immediately pick out a concise description of the error (the types are on their own lines) without making it impossible for a beginner to understand what's going on.

Coming from Haskell, I'm also impressed by what Elm chooses to leave out. The Signal abstraction provides a very clean, relatively easy to understand interfact between the mathematical, happy world of stateless pure functions and, you know, actually running the program on a computer somewhere and impacting the outside world. Meanwhile Elm's polymorphic records provide a flexible, secure and simple alternative to Haskell's type classes and higher-kinded types. No monads here, and logging `x` to the console to debug it is as simple as changing it to `Debug.log x` -- no cascading changing of type signatures or monad transformers needed.

Elm roadblocks:
- random numbers
- understanding Signals (don't unwrap a signal; don't use more signals than you have to)
