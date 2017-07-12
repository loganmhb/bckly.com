---
title: Some updates on Logos
date: 2017-07-12
---

It's been almost a month since I first [posted][original] about
[Logos][logos-git], the database project I'm spending most of my time
on here at RC. I've made some good progress and we're now into the
second half of my batch, so here's an update on where things stand.

## Buffered indexing

The main feature I was interested in working on a month ago was
buffering changes to the database's indexes in-memory. This buffering
is desirable both for write speed and for storage efficiency. Because
the indexes are stored as wide, persistent trees, each new fact
written would require 3-4 new nodes per index to be created in the
backing store; since each node might contain thousands of pieces of
data, that's a lot of wasted space!

The solution is to wait until a large number of new facts are
available, and then write them into the backing store in a batch,
creating only as many nodes as required to maintain the sort order of
the tree.[^sort] In order to avoid losing data in a crash it's still
necessary to write each item into the backing store in a transaction
log as it arrives, but this transaction log does not have to support
queries and so doesn't have the efficiency problems of the indexes.

This creates a bit of additional complexity at query time: in order to
see the current state of the database, you need to merge what's in the
backing store with the new data in memory. But this is pretty simple
if you keep the in-memory data stored in a sorted tree as well. It's
not necessary to merge all of both trees before running the
query. Instead, you can retrieve the desired range of items from each
tree separately and lazily merge those much smaller sets.

This is mostly implemented. Logos's indexes now have two components: a
durable, persistent B-tree-like data structure[^btree] for the main
indexes, and a persistent red-black tree implementation for the
buffered in-memory data. The transactor logs transactions to the
backing store and waits for a large number of items to build up in
memory before modifying the main indexes; then it rebuilds them from
scratch. (This can happen in the middle of processing a query and
takes quite a while, which is obviously not very desirable.)

There are two big improvements that I'd like to add here. First, the
reindexing should happen asynchronously in the background instead of
blocking transactions[^throttling]. Second, it's a huge waste to
rebuild the whole index every time; all the data nodes that don't
overlap with the in-memory tree can be reused. If you're importing
sorted data, this means you could reuse the whole tree!

## Retracting facts

In the Datomic model of the world which Logos subscribes to, you never
delete a fact.  Instead, you add a retraction of that fact to the
database. But when you're querying the database, you usually don't
want to see all the past versions of facts that have been retracted;
you only want what's true now. Data from the past is available on
request, but does not appear by default.

Logos now provides the ability to retract a fact, fulfilling part of
this vision. Retracted facts remain in the database, but so far there
is no way to query for them. In the future when I get to adding
queries as-of a particular point in time, retracted facts that were
true at that point in time will appear. I'm also thinking about other
ways you might want to query the database in which it would make sense
for retractions to be included, but I haven't arrived at any firm
conclusions yet.

## Attribute schemas

I didn't discuss attribute schemas in too much detail in the last post
because there wasn't a lot to say about them. Most databases have
schemas of some sort (explicit or implicit) and type-checking at the
database level can be a helpful way of ensuring data integrity.

Datomic uses schemas at the attribute level: it doesn't require an
entity to have any particular attributes, but if an entity does have
an attribute, the attribute's value must obey the schema. Logos now
has a basic version of this feature as well. In order to use an
attribute, you must first declare its value type. You do that by
creating an entity for the attribute that looks like this:

```
{db:ident person:name
 db:valueType db:type:string}
```

A couple of other primitive types are supported (references and
identifiers), though I'd like to add more. (This would probably also
be a pretty simple way to contribute to the project for anyone who's
interested, since it wouldn't need to touch the complexity of the
indexing code or backing stores.)

## FFI

I mentioned as a stretch goal in the last post that I'd like to be
able to use Logos from a webapp written using something like
Python/Flask. This isn't really a core part of the project, but it is
fun and interesting, so I've put a bit of work into adding a API
suitable for use through the C foreign function interfaces that most
languages provide. As a proof of concept, I successfully ran a query
from the Python interpreter by passing everything back and forth
through the FFI as strings. The next steps here would be to pass
structured data back and forth over the FFI, and perhaps define a
small library to make using Logos from Python easier.

[logos-git]: https://github.com/loganmhb/logos

[original]: https://bckly.com/2017-06-14-logos.html

[^sort]: I still am not
sure about the exact complexity properties of this process, but it's
much more efficient than writing O(nlog(n)) nodes for every write.

[^btree]: Because of the way the tree is constructed in batches, it
makes more sense to store all the data in leaf nodes like a B+-tree
and build up the small superstructure separately. But because the tree
is persistent and needs to share structure with older versions of
itself, the links between leaf nodes that characterize a B+-tree
aren't practical. I'm not sure if there is a specific name for the
resulting structure, but it's close enough to a B-tree to have most of
the same important properties.

[^throttling]: The main bit of complexity here is preventing
transactions from overwhelming background indexing jobs. If one
background indexing job can't finish before the next is due to start,
the transactor would then need to start throttling transactions in
order to allow the indexing jobs to catch up.