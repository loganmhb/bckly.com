---
title: Logos
date: 2017-06-13
---

For the past few weeks, I've been at the Recurse Center working on
something I keep referring to as "the database project." In this post
I'll outline my plans for it and what I've done so far -- mostly for
my own benefit and to gain clarity, but also as a primer for anyone
else who might be interested. (And if it sounds so interesting that
you want to help, let me know!)

The project is called [Logos][logos-git][^name]. It's a graph database
heavily based on [Datomic][datomic], which has an unusual set of
features that I couldn't find in any existing open-source
databases.[^mentat] There's an overview of Datomic's design on the
[rationale page][rationale]; I also found Rich Hickey's talk
["Deconstructing the Database"][deconstructing] helpful in
understanding the design and its benefits.

The set of features I'm interested in replicating is something like
this:

### 1. An append-only log of facts

The database consists of an append-only log of facts. Instead of
deleting facts which are no longer true, you retract them; the
retraction itself is a fact added to the database, which allows you to
determine both that the fact is no longer true _and_ the time before which it
was true. Because the entire history of the database is present in the
transaction log, you can derive the state of the database at any point
in the past as well as the current state for querying.

### 2. Entity-attribute-value information model

The information model is a triple-store, like RDF -- facts in the
database consist of an _entity_ (i.e. an ID referring to a unique
thing), an _attribute_, and a _value_. Datomic adds to the classic
triple-store an additional field for the transaction in which the fact
was added; thus, time is an intrinsic property of the data. From the Datomic rationale:

> Once you are storing facts, it becomes imperative to choose an
> appropriate granularity for facts. If you want to record the fact
> that Sally likes pizza, how best to do so? Most databases require
> you to update either the Sally record or document, or the set of
> foods liked by Sally, or the set of likers of pizza. These kind of
> representational issues complicate and rigidify applications using
> relational and document models. This can be avoided by recording
> facts as independent atoms of information. Datomic calls such atomic
> facts 'datoms'. A datom consists of an entity, attribute, value and
> transaction (time). In this way, any of those sets can be discovered
> via query, without embedding them into a structural storage model
> that must be known by applications.

The query language for the database is a declarative variant of
Datalog, similar to SPARQL. The query engine executes necessary joins
without requiring the programmer to explicity declare them. Compare a
query to get replies to all posts by a particular user in SQL and
Logos's Datalog variant:

```sql
SELECT c.contents
FROM comments c
JOIN posts p ON comments.parent_id = posts.id
JOIN users u ON posts.user_id = users.id
WHERE u.email = 'me@me.com'
```

```
find ?comment where
  (?user email 'me@me.com')
  (?post author ?user)
  (?comment parent ?post)
```

Relationships that SQL expresses via joins are expressed in terms of
attributes in the Datomic/Logos/Datalog model. If the SQL query needed
to be recursive -- say, if the comments were threaded -- the
difference would be more stark; the Datalog model can easily extend to
arbitrary graph relations, whereas SQL quickly breaks down when
working with heavily interlinked data.

### 4. Attribute-level schemas

The database schema is defined and enforced in terms of what kinds
of values an attribute can have, but _not_ in terms of what attributes
an entity can have, so the schema can be flexibly grown over time. In
this respect it occupies a middle ground between relational databases
and document stores; it supports data joins even more naturally than a
relational database, and schema extensions as easily as a document
store. (Of course, the performance situation is not trivial -- several
different indices are required in order to support different types of
queries, and maintaining them can be expensive, so in practice some
compromises are necessary.)

### 5. Separation of reads and writes

This one is, in my opinion, the kicker, and the thing that I
haven't been able to find in other open-source projects. The database
is divided roughly into three components. The _transactor_ is the
process responsible for handling writes to the database. In order to
maintain transactional consistency, only one thread in one process is
responsible for executing all transactions and storing the new data,
for which both Datomic and Logos rely on the second component, an
external K-V store.

The transactor writes facts into the key-value store in the form of
segments of each index, and each segment is large -- hundreds or
thousands of facts, like a page of a B-tree. (Logos's current
implementation uses a persistent B-tree with structural sharing, so
that when new facts are added any process that still has a reference
to the old root node of the index can continue to use it as long as
they need to.) The third component of the database is a _library_ that
clients can use to execute queries and request transactions from the
transactor. Because data added to the indexes in the backing store is
immutable, clients reading from the database only need a handle to the
root node of the latest index, and then they can read all the data
they need _directly_ from that key-value store without coordinating at
all with the transactor. Moreover, the chunks of data in the key-value
store can be cached client-side, so if a client wants to do a
computationally-intensive query, they can do that by retrieving only
the data they need from the backing store and then doing all the
expensive computation locally, without interfering with other
processes sharing the database. You could therefore run heavyweight
analytics queries against the same database servicing low-latency
transactions with relatively little performance interference (all
processes do have to share the backing store if their caches do not
contain the necessary data).

## Where am I now?

This is all a bit of a grandiose plan for a three-month project; what
I've described above is the aspirational architecture of Logos. As it
stands, Logos is a Rust application that can store and query data
either in-memory, locally in a SQLite database, or externally in a
Cassandra cluster; however, there is very little schema facility, no
support for retracting facts or querying historical versions of the
DB, no in-memory buffering of changes to the index (which is necessary
to avoid `nlog(n)` growth in space usage with a large constant factor
as you add index segments), no separation between the client and the
transactor, and many other smaller features that are missing from the
query language.

However, I am more optimistic than when I started the project that
I'll be able to implement the separate transactor component and client
library while I'm here at RC, and perhaps complete some other smaller
features as well, though I will certainly not achieve anything like
the performance, high-availability guarantees, or transactional
capabilities of Datomic in that short time. My stretch goal for the
end of the batch is to implement enough features that I can write a
small Twitter-style webapp in Python that uses the database libary via
an FFI; we'll see if I can actually get that far.

[logos-git]: https://github.com/loganmhb/logos

[datomic]: http://www.datomic.com/
[rationale]: http://www.datomic.com/rationale.html
[deconstructing]: https://www.youtube.com/watch?v=Cym4TZwTCNU

[^name]: The name is a play on a combination of Datalog, transaction
logs, log-structured merge trees, and the original meaning of the
Greek word "logos" as something like "account" or "ground." It was not
intended as a play on my name, though I now realize the two are a
little uncomfortably close.

[^mentat]: The closest I could find is [Project
Mentat](https://github.com/mozilla/mentat), a Mozilla project also
drawing heavily on Datomic, but Mentat is designed to be embedded and
lacks all of Datomic's distributed features.