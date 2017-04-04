---
title: Setting up a programming environment in ChromeOS
layout: post
date: September 18, 2016
---

I recently got a Dell Chromebook 13 to use as my personal laptop, replacing a seven-year-old Macbook. I've spent a couple weeks experimenting to figure out the best setup for programming and writing (both of which I do mostly in Emacs running in a terminal).

My original plan was to use [Crouton][crouton] with Ubuntu installed alongside ChromeOS for everything except web browsing. Crouton is a set of scripts for running a Linux installed alongside ChromeOS in a lightweight chroot environment. It works surprisingly well and I was able to get a XFCE desktop running without too much trouble. There is some friction, however, switching back and forth between ChromeOS and the chroot -- sometimes the Linux environment hangs or the graphics glitch, and occasionally I ran into issues where the Chromebook screen would go black and I'd have to restart.

It's not really surprising that Crouton has issues like this -- it's really impressive how well it works, considering the hoops it jumps through to make the Linux environment work seamlessly alongside ChromeOS (you can even share a clipboard between the two). But it was a little too irritating for me to use most of the time, especially since I hardly ever need a desktop environment besides Chrome, which ChromeOS already gives me.

Fortunately, it's possible to run a shell in a window in ChromeOS. The built-in crosh shell runs in a Chrome tab, which causes problems sending certain key sequences (e.g. control-T will open a new Chrome tab instead of sending the C-t key sequence through to the terminal). This makes Emacs pretty hard to use, but fortunately there's a workaround. If you open the crosh shell in a Chrome tab with control-alt-t, you can select "More tools" -> "Add to shelf", and check the "Open as window" box. Then you can open crosh from the shelf icon and control key sequences will work normally. You'll also need the Secure Shell extention if you want to SSH into another machine -- if you're using a chroot it's not necessary.

I ended up wiping the old Macbook and installing Arch Linux on it, so my new setup is to spend most of my time in a crosh shell window connected to the Arch server over SSH. That gives me the out-of-the-box fonts and nice appearance of ChromeOS along with the full control over the OS that Arch brings. You could do basically the same thing with a chroot instead of a server; I just happened to have the old laptop lying around that has a little more power and disk space on it. I'll keep the Crouton environment for when I need an actual desktop app that's not available on ChromeOS, but so far my only use case for that is the CGoban client for the KGS go server.

I'm pretty pleased with the setup overall -- I wouldn't recommend it for non-programmers who want more than a web browser or for people who don't want to do a little tinkering, but if you're looking for an affordable, light laptop outside the Apple tent the Chromebook isn't a bad way to go.

[crouton]: https://github.com/dnschneid/crouton 
