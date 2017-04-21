---
---

Yesterday I received a new keyboard in the mail: an Ergodox EZ. The Ergodox, if you're unfamiliar, is an open-source keyboard design. Normally, in order to get one, you have to buy the parts yourself or participate in a group buy on MassDrop, which is slightly cheaper but only happens when enough people sign up for the buy. I was hoping to wait for the next group buy and assemble the keyboard myself, since I enjoyed that process for my last current keyboard (an Atreus). The EZ convinced me, though. As the name implies, it's a pre-assembled version of the Ergodox that you can order. Mine arrived much more quickly than I expected -- I ordered it on Sunday and it was in my hands by Wednesday at noon.

Since I didn't assemble the keyboard myself, I wanted to at least hack on the firmware a little bit. It turns out this is straightforward -- the keyboard comes with some stock firmware (which is a little strange for my taste) but the firmware is totally open source and pretty easy to get started with if you know a little C. If you'd rather not do any programming, there's a configuration tool available on MassDrop's website. You can design a key layout using a graphical interface, then download a .hex file containing the compiled firmware.

On the first day I went through several iterations of firmware designed using the MassDrop tool, mostly moving around punctuation and modifier keys. I'm used to typing on the extremely small Atreus, so I'm still figuring out which places are comfortable for my fingers to stretch to.

A useful feature of the firmware the MassDrop tool uses is that it allows you to define several different layers -- essentially extra layouts that you can either temporarily activate by holding down a key, or switch to for longer by pressing a key. The Atreus has this feature as well to cope with its small size (inspired by the Ergodox, possibly) so I'm used to holding down a key in order to access parentheses, punctuation and so on.

-- colemak layer
-- hack some c to activate the LEDs
