---
title: Setting up a programming environment in ChromeOS
---

I recently got a Dell Chromebook 13 to use as my personal laptop, replacing a seven-year-old Macbook. I've spent a couple weeks now experimenting to figure out the best setup for programming and writing (both of which I do mostly in Emacs in a terminal).

My original plan was to use [Crouton][crouton] with Ubuntu installed alongside ChromeOS to use for everything except web browsing. Crouton is a set of scripts to allow you to run a Linux install in a lightweight chroot environment. It works surprisingly well and I was able to get a XFCE desktop running without too much trouble. There is some friction, however, switching back and forth between ChromeOS and the chroot -- sometimes the Linux environment hangs or the graphics glitch, and occasionally I ran into issues where the Chromebook screen would go black and I'd have to restart.

It's not really surprising that Crouton has issues like this -- it's really impressive how well it works, considering the hoops it jumps through to make the Linux environment work seamlessly alongside ChromeOS (you can even share a clipboard between the two). But it was a little too irritating for me to use most of the time, especially since I hardly ever need a desktop environment besides Chrome, which ChromeOS already gives me.

Fortunately, it's possible to run a shell in a window in ChromeOS. The built-in crosh shell runs in a Chrome tab, which causes problems sending certain key sequences (e.g. control-T will open a new Chrome tab instead of sending the C-t key sequence through to the terminal). This makes Emacs pretty hard to use, but there are a couple of extensions you can install to run the shell in a window instead: Crosh Window and Secure Shell.

I ended up wiping the old Macbook and installing Arch Linux on it as a file server, so my new setup is to spend most of my time in a crosh shell window connected to the Arch server over SSH. That gives me the out-of-the-box fonts and nice appearance of ChromeOS along with the full control of Arch. You could do basically the same thing with a chroot instead of a server; I just happened to have the old laptop lying around that has a little more power and disk space on it. I'll keep the Crouton environment around for when I need an actual desktop app that's not available on ChromeOS, but so far my only use case for that is the CGoban client for the KGS go server.

I'm pretty pleased with the setup overall -- I wouldn't recommend it for non-programmers who want more than a web browser or for people who don't want to do a little tinkering, but if you're looking for an affordable, light laptop outside the Apple tent the Chromebook isn't a bad way to go.

[crouton]: https://github.com/dnschneid/crouton 
