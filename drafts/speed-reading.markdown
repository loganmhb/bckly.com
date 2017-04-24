---
title: Speed readers and premature optimization
---

The other day I noticed that my phone's Kindle app had a feature called "Word Runner." I'm a sucker for dictionaries and thesauruses and so forth, and hoping it was something like that I clicked on it. I was disappointed to find this:

[picture of word runner, hopefully]

I've seen several similar apps designed to increase your reading speed, but I hadn't actually used one before, so I gave Word Runner a brief try. It was depressing. Reading one word at a time was indeed faster, but the words felt unmoored from the text, unspooling quickly before me but failing to accumulate any real context or meaning. It's hard enough to read a book at a normal pace and retain all the information you want to; if I used this, I can't imagine learning much of anything.

I was curious what research has been done on this -- do speed readers actually enable you to read more in the same amount of time, or do you sacrifice comprehension to gain that speed? The answer, from all the science I can find, is yes. You can't gain much reading speed without sacrificing comprehension. According to an [article][aps] from the Association for Psychological Science:

> While some may claim prodigious speed reading skills, these claims
> typically don’t hold up when put to the test. Investigations show
> that these individuals generally already know a lot about the topic
> or content of what they have supposedly speed-read. Without such
> knowledge, they often don’t remember much of what they’ve read and
> aren’t able to answer substantive questions about the text.

This, apparently, is true of all of the various techniques speed-reading aficionados advocate. A [review][rayner] last year examined many different approaches to speed-reading and found that none of them avoided the fundamental trade-off between speed and comprehension.

I find this particularly frustrating as a programmer. WordRunner and its ilk work by changing the format in which text is presented in order to improve some quantifiable metric -- words per minute, in this case. But as usual this comes at the cost of the less quantifiable but more important quality of comprehension. A tool like WordRunner might have a place as an informed trade-off (though I find it hard to imagine wanting to read something that I don't care very much about comprehending) but instead it's presented as a panacaea that will help readers ("read faster!").

This is a category of mistake that programmers seem especially prone too, and I think it's a pernicious one. There are a number of adages it brings to mind -- [Goodhart's Law][goodhart] posits that "when a measure becomes a target, it ceases to be a good measure." There's the saying that when you have a hammer, everything looks like a nail. I think the fundamental problem here is that programmers are used to solving problems with technology, so when they encounter problems that don't really have great technological solutions (whether it's reading speed or biased news sources), they choose a subset of the problem to solve that _does_ have a straightforward technological solution (show me the words faster!), ignoring or minimizing the pieces of the problem their solution doesn't solve.

Maybe there are ways to use technology to improve reading, but focusing on shallow metrics like speed at the expense of what's really important won't help anybody.


[aps]: https://www.psychologicalscience.org/news/releases/speed-reading-promises-are-too-good-to-be-true-scientists-find.html
[rayner]: http://journals.sagepub.com/stoken/rbtfl/0GSjhNaccRKTY/full
[goodhart]: https://en.wikipedia.org/wiki/Goodhart%27s_law
