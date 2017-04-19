---
title: ship, a Python shell
layout: post
date: July 20, 2016
categories: code
---

[Here's][gitlink] a fun project I spent an hour or so working on today. It's called ship, and it's a shell! (Sort of, in an impoverished kind of way.)

# what is shell

I started thinking about a project like this after I came across this [workshop material][shelltut] by Kamal Marhubi. "Most of us use a shell, at least once in a while," it begins. True enough! But I've never figured out how mine works. I have found building a super-simple version of the thing in question to be a good solution to this problem.

I've been writing a lot of Clojure and a little Rust lately, but this was pretty unix-y and I didn't want to go too low-level (yet!), so I decided to write it in Python.

What does a shell do?

1. take some input
2. (usually) split it up into a program and some arguments, then call the program with those arguments
3. repeat

2) is the tricky part. This involves parsing the input, then a few system calls to create a new process and then wait for it to finish.

Parsing the input is by far the most complicated and error-prone part of all this, and was the main reason I decided to use Python -- that wasn't really what I was interested in learning about.

I thought even with Python I'd have to write a little code to do the splitting and parsing, but it turns out the Python standard library comes with a module called `shlex` that does exactly what I needed. Batteries included, indeed. (Writing this in Python started to feel like cheating, in fact, since Python has such extensive support for subprocesses built in. I'm now curious to repeat the experiment in Rust or C.)

# system calls

Now comes the fun part. Once the shell has the name of the program it needs to invoke and the list of args (say, `['grep', '-r', 'cats', 'src/']` -- the name of the program is conventionally the first argument as well) it can use the `execv()` system call to start that program (or one of the other variants of exec*() -- there are more than I realized!). But there's a problem: `execv()` transforms the calling process (the shell) into the new process. I'd only ever be able to run one command in a session, because the shell would have to sacrifice itself in order to run the first command! Not a very useful shell.

To get around this, the shell can first use the `fork()` system call. `fork()` fascinates me -- it creates an _exact_ copy of the calling process, including memory layout and point of execution. The only difference between the parent process and the child process is that in the parent process, `fork()` returns the child's PID, while in the child process `fork()` returns 0. You can use this to take different actions in the parent and child like so:

```python
# fork_test.py
import os

print "Hi from the parent process!"

pid = os.fork()

if pid == 0:
    print "Hi from the child process!"
else:
    print "Hi from the parent again! Created child %d" % pid
```

When I ran that, it looked like this:

```
  $ python fork_test.py
  Hi from the parent process!
  Hi from the parent again! Created child 1655
  Hi from the child process!
```

Note that the parent process continues right along before the child process gets going -- creating a process involves some overhead at the OS level, as I understand it, and so takes a little while. This is actually a problem for the shell, because we don't want to prompt the user for the next command until the previous one is done running. To get around this, there's the `wait()` system call, which waits for a child process to exit, like so:

```python
import os

print "Hi from the parent process!"

pid = os.fork()

if pid == 0:
    print "Hi from the child process!"
else:
    pid, status = os.wait()
    print "Hi from the parent again! Created child %d which exited with code %d" % (pid, status)
```

I found it surprising that `wait()` doesn't require the pid as an argument -- I'm curious how it works when there's more than one child process. But with this all the pieces are in place for a shell! We just have to wrap the whole thing in a loop and replace printing a greeting from the child process with `execv()`ing the program. You can see the resulting program [here][permaship]. It is extremely tiny! But it works surprisingly well.

I ended up using Python's `os.spawnve()`, which basically wraps `fork()`, `execv()` and `wait()`. This also felt a little bit like cheating, but it's an educational exercise, after all. All of these Python standard lib calls are actually lower-level than Python wants you to be working -- there's a `subprocess` module which encapsulates these and more, including I/O and pipes -- but it felt more educational to figure out how this works at a low level.

Next steps for this little shell are pipes, I/O redirection and globbing!

[gitlink]: https://github.com/loganmhb/ship
[shelltut]: https://github.com/kamalmarhubi/shell-workshop
[permaship]: https://github.com/loganmhb/ship/blob/blog_post_state/ship.py
