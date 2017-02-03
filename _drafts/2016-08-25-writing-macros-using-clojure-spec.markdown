---
title: Writing Macros with clojure.spec
draft: true
date: August 25, 2016
categories: code
---

Last night I attended Papers We Love NYC for the first time, where David Nolen talked about the paper ["Parsing with Derivatives."][pwd] Since that paper was the basis for the implementation of clojure.spec, the discussion after the talk was over included a lot of questions about spec. I'd read the spec announcement and guide and played with it a little bit at the REPL, but until last night I didn't understand one particularly exciting use of spec: parsing macro bodies.

Until now, macro authors who wish to implement some kind of syntax in their macros have been required to hand-write the code needed to parse users' input into a form the macro can use to generate code. This results in complex code, often with poor error messages, since providing helpful errors on top of a handwritten parser is more complicated than most macro writers want their macros to be. With spec, it's now possible to define the structure of your macro's body using a model similar to regular expressions. This buys you two things: spec can automatically generate error messages, and `s/conform` can convert your user's input into a parse tree.

As an example of this, here is the `for` macro from `clojure.core`, rewritten using a spec for the binding vector.

The `for` macro will be invoked like this:
``` clojure
(for [x [:a :b :c]
      y [1 2 3]]
  [x y]) ;=> ([:a 1] [:a 2] [:a 3] [:b 1] [:b 2] [:b 3] [:c 1] [:c 2] [:c 3])
```

It takes two forms: a binding vector and a body. The binding vector contains binding forms (destructuring is supported) on the left and sequences of some sort on the right. The return value is a lazy sequence of values obtained by evaluating the body (in this case, `[x y]`) with each value of the sequence in turn. When there are multiple sequences, as here, each combination of values gets evaluated -- for example, the expression `[x y] gets evaluated with `x` bound to `:a` as `y` is bound to `1`, then `2`, then `3`, and so on.

Finally, the binding vector in `for` supports several control structures: you can bind additional values using `:let`, ignore certain values using `:when`, and consume only part of a sequence using `:while` -- for an example of a `for` macro with complex bindings, see Mark Engelberg's [post on logic programming][logic-overrated]. So there's quite a bit of syntax here that the macro implementation will have to deal with.

To parse the syntax of the binding vector, I'll use a spec. (If I wanted to verify the correctness of the whole form and provide more helpful error messages, I could write a spec for the whole macro, but for the purposes of this post I'm only interested in parsing, so I'll just spec the binding vector.)

The binding vector contains any number of bindings. Each binding is a left-hand value, a right-hand-value, and some modifiers (:when, :let, or :while) accompanied by a body. A correct spec would verify that the binding forms are valid and the right-hand values are sequences, but for parsing a more minimal spec suffices:

``` clojure
(require '[clojure.spec :as s])

(s/def ::for-bindings
  (s/* (s/cat :lval any?
              :rval any?
              :modifiers (s/* (s/cat :type #{:when :let :while}
                                     :modifier-body any?)))))
```

`s/*` works just like the regular expression `*` operator, allowing any number of values. `s/cat` specifies a sequence of items (as in concatenation), each of which is named by a keyword. So with this spec defined, `s/conform` can coerce a binding vector into an easier-to-use parse tree:

``` clojure
(s/conform ::for-bindings '[x (range 10)
                            y [:a :b :c]
                            :when (even? x)])
;=> [{:lval x, :rval (range 10)}
     {:lval y, :rval [:a :b :c],
     :modifiers [{:type :when, :modifier-body (even? x)}]}]
```

This still requires some work to get to the data structure we need, but it's much easier to operate on than the raw binding vector and the spec provides some validation. 

[pwd]: http://matt.might.net/papers/might2011derivatives.pdf
[logic-overrated]: http://programming-puzzler.blogspot.com/2013/03/logic-programming-is-overrated.html
