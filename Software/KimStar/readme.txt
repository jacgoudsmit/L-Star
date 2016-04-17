This directory (and subdirectories) contain the software that I used for a little experiment.

I've owned a MicroKim by brielcomputers.com for years, but it's been defective for a long time. It appears that the EPROM may be malfunctioning or may have been partially erased, but at the time of this writing, I'm not sure.

In order to analyze the problem, I connected a Parallax Propeller QuickStart board to the MicroKim expansion bus with some female-male breadboard connector wires. Then I copied the Apple-1 emulator software of the L-Star project and made some changes: I removed the video module, the keyboard module and the clock module, and made a few small changes so that it uses a different pin for the clock, which is now an input (PHI2), not an output. With the address decoder jumper removed from the MicroKim (and the Single-Step switch set to OFF), the 6502 on the MicroKim now only "sees" the devices emulated by the Propeller. A wire can be connected from the Propeller to the DEN pin on the MicroKim expansion port to enable the on-board devices.

This makes it possible to do diagnostics by selectively controlling the on-board address decoder, and/or emulating KIM devices and ROM/RAM in the Propeller.

The first experiment is the Apple-1 emulator in the 1-Apple1 directory. The address decoder stays disabled, and the Propeller emulates the Apple-1 ROM (really the Replica-1 ROM with BASIC and Ken Wessen's Krusader), simply to demonstrate that the 6502 works.

The second experiment (which I called "2-Kimple1") is almost equal to the first one, but now a small bit of PASM code enables the internal address decoder to make the RAM, ROM and RIOT visible. This makes it possible to use Woz mon from the Apple 1 (or Krusader) or even Apple Basic to program Kim programs. Note: I was having trouble with Krusader; quite possibly it needs more patches to run with 5K RAM instead of 32K. I'll look at this later.

The third experiment (which I called "3-MicroPle1") changes the code that enables the internal address decoder so that it only does this for the RAM and RIOT ($0000-$17FF). The Propeller provides the ROM image at $1800-$1FFF. I needed this because apparently my EPROM is b0rked: it has a number of corrupted bytes in it. This way, I could map the original KIM-1 ROMs into memory and just type 1C22R in Woz Mon to start the Kim monitor. Awesome!

One of the things that many people want to do with the MicroKim is to run Microsoft Basic. The version of BASIC for the KIM-1 was one of the first versions of the 6502 BASIC interpreter that Microsoft distributed (according to some thorough research by Michael Steil at pagetable.com who compared many different versions) but it works really well. The problem is that it takes a long time to load via the TTY (punch tape emulation), let along via the cassette interface on the original KIM-1. The directory 4-BasiKim contains a version of KimStar that maps BASIC into a ROM area at $2000. To start it, enter 4065 <space> G on the MicroKim terminal.


The Propeller is not officially 5Volt-tolerant and the MicroKim uses 5V, so this isn't officially supported. 