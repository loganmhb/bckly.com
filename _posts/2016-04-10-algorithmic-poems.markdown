---
title: Algorithmic Poetry
layout: post
category: code
tags: art, clojure
---

This weekend I experimented with using Clojure to write poetry. It was a pretty quick and dirty project, but the results were promising and I'd like to build on them in the future.

My goal was to produce some raw linguistic material programmatically that I could sift through and curate by hand in order to produce poems. I thought that the simplest way to produce interesting text was probably to use some source text (I chose Moby Dick) and [Markov chains][markov]. If you're not familiar, a Markov chain is a method for randomly generating streams of content (often text, but it can be used for any sequential kind of data). The method works by assembling a lookup table mapping values that occur in the sequence to the set of values that can follow them. You can implement this in a variety of ways, but I chose a fairly simple version. I split the text of Moby Dick into words, stripping out punctuation and capitalization, then mapped each pair of words to possible continuations. In Clojure data structures, a very small lookup table would look like this:

```
;; Text: "It is not much but it is something."

{
  ["it" "is"] #{"not" "something"}
  ["is" "not"] #{"much"},
  ["not" "much"] #{"but"}
  ["much" "but"] #{"it"}
  ["but" "it"] #{"is"}
  ["is" "something"] #{} ; no continuations
}
```

Generating the Markov chain with Clojure turned out to be quite simple. It looks something like this:

```
(defn text->words
  "Split a file on whitespace or punctuation, remove things that
   don't look like words, and lowercase everything."
  [text-file]
  (->> (clojure.string/split (slurp text-file)
                             #" |\n|:|\.|;|\-|,|\"|\!|'|\?"
       (filter (partial re-find #"[a-zA-Z]"))
       (map clojure.string/lower-case))))


(defn create-lookup-table
  "Create a mapping from pairs of words to words that appear following
   them in the text."
  [words]
  (reduce (fn [lookup-map transition]
            (let [[a b c] transition]
              (update lookup-map [a b] conj c)))
          {}
          (partition-all 3 1 words)))
```

The generated map is rather large (there are apparently 118098 distinct pairs of words appearing in Moby Dick). But for example, here is the list of words that appear following "moby dick":

```
("sideways" "seeks" "was" "seemed" "on" "two" "had" "cried" "bodily" "casts" "at" "and" "swam" "now" "with" "moved" "fired" "that" "and" "had" "i" "it's" "and" "doesn't" "as" "have" "himself" "in" "pooh" "was" "and" "not" "was" "and" "we" "rose" "but" "'moby" "to" "for" "for" "they" "for" "was" "though" "as" "and" "into" "had" "had" "which" "he" "had" "not" "was" "and" "the" "with" "those" "such" "yet" "it" "i" "to" "god" "god" "that" "that" "that" "but" "captain" "moby" "ye" "moby" "or")
```

Note there are some duplicates. My implementation is fairly naive and adds duplicates of a word if it appears more than once following a pair. This makes it easy to select more common words more often, but makes the lookup table larger than it strictly needs to be. I don't really care about that for this quantity of text, but if you were operating on a really large corput you'd want to change the implementation so that it tracks the set of following words and their associated frequencies in a nested map instead of just adding words every time. That makes the code more complicated, though, so I didn't do it yet. Some of the continuations also don't make much sense, such as "moby dick i". This is probably because of the punctuation I stripped out; if a sentence ends with "Moby Dick", pretty much any word can come after it. That's a downside to stripping out punctuation, but the upside is the lookup table doesn't have separate entries for "moby dick", "moby dick!" "moby dick?" and so on, which makes it more flexible. Either choice comes with tradeoffs.

Now that we have the lookup table, we need a way to generate an actual chain of text.

```
(defn generate-text
  "Creates a lazy sequence of words based on the lookup-map."
  ([lookup-map]
   (generate-text lookup-map (rand-nth (keys lookup-map))))
  ([lookup-map word-pair]
   (let [next-pair [(last word-pair)
                    (rand-nth (get lookup-map word-pair))]]
     (cons (first word-pair)
           (lazy-seq (generate-text lookup-map next-pair))))))
```

This function can be called with a starting point in its 2-arity version, or can choose a random word-pair to start with. Then it lazily walks the lookup table, building a sequence of words.

The results look like this:

```
(def lookup-table
  (create-lookup-table
    (text->words "resources/moby_dick.txt")))

(clojure.string/join " " (take 500 (generate-text lookup-table))

;=> "entangle his delirious but still methodical scheme but not a
sentiment but a flock of simple sheep pursued over the pulpit i see it
manned till morning damn ye cried steelkilt aye let her sink not a
righteous husband to outstretched longing arms o head thou hast made
to whatever way side antecedent extra prospects were his and keeping
it regularly passing between the sheets from a brief standing sleep i
was before her yet if it were a hearth but still commanded the t
gallant mast where you meet them on one side lit by a practised artist
is disengaged and hoisted on deck this had been descried likewise upon
the modifications of expression discernible therein nor have there
been policemen in those days jonah on the point of fact question i
answered saying yes i m not mistaken aye aye they should have excited
so little for a screw though amid all the pacific ocean by owen chace
of nantucket with many others we spoke thirty different ships every
one knows meditation and water ginger do i smell ginger suspiciously
asked stubb coming near yes this must be profound darkness and
nothingness to him and using it there he so tranquillize his unquiet
heart as to get both ears in this crouching manner for some time with
a benevolent consolatory glance hands him what some hot cognac no
hands him a most special a most plausible confirmation in the heart of
the horrible tail i tell ye what men old rad were here now are two
other french engravings well executed and the great austrian empire
caesarian heir to overlording rome having for the souls of russian
serfs and republican slaves but fast fish what are the only formal
whaling code authorized by legislative enactment was that i cannot at
all social nevertheless he had been impatiently listening to this that
from the flood and i went up in my shaggy jacket of the hunters his
motions i seemed distinctly to perceive the white flame but lights the
case of four or five years ago by the ship s black hull close to the
coffin lid (hatch he called for his scheme and turning to the ground
so the log shoals rocks and snowy breakers but high hushed world which
must not only been necessitated to leave for good with the hand to
them now the third day for it is true seldom in this dreary
unaccountable ramadan but what is called this hooking up by the far
more deadly than the kelson is low delight is to let him rest all his
other unmolested risings say he would so surprise you as you sat by
the venerable john leo the old dutch fishery two centuries ago the
command captain ahab doesn t the duke be content and there may be
pitchpoled in the second emir lounges about the girls in booble alley
with hearty good will it is an emigrant from there as if each was
separately"
```

Cool! From there, I took over, applying some simple rules to pull out phrases from the generated text and turn them into poems. The rules were:

1. Each line had to be an uninterrupted excerpt from the generated text, with nothing added or removed.
2. Between lines, I could optionally skip text.
3. I could add punctuation freely.
4. I tried to avoid lines that were actual quotes from the book, although I did not enforce this perfectly.

The results are [here][mb_poems]. Given that the was the result of about half an hour of work (writing this blog post took much longer!) I'm excited to refine the method. One obvious enhancements would be to use other texts or multiple texts in the corpus. Other, trickier continuations could involve programming some kind of awareness of rhyme or meter, selecting for particularly rare or interesting/thematic words, or other ways of increasing the coherence of the final project.

[markov]: https://en.wikipedia.org/wiki/Markov_chain
[mb_poems]: /moby_dick_poems.html
