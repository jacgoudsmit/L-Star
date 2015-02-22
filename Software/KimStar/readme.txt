This directory (and subdirectories) contain the software that I used for a little experiment.

I've owned a MicroKim by brielcomputers.com for years, but it's been defective for a long time. It appears that the EPROM may be malfunctioning or may have been partially erased, but at the time of this writing, I'm not sure.

In order to analyze the problem, I connected a Parallax Propeller QuickStart board to the MicroKim expansion bus with some female-male breadboard connector wires. Then I copied the Apple-1 emulator software of the L-Star project and made some changes: I removed the video module, the keyboard module and the clock module, and made a few small changes so that it uses a different pin for the clock, which is now an input (PHI2), not an output. With the address decoder jumper removed from the MicroKim (and the Single-Step switch set to OFF), the 6502 on the MicroKim now only "sees" the devices emulated by the Propeller. A wire can be connected from the Propeller to the DEN pin on the MicroKim expansion port to enable the on-board devices.

This makes it possible to do diagnostics by selectively controlling the on-board address decoder, and/or emulating KIM devices and ROM/RAM in the Propeller.

The first experiment is the Apple-1 emulator in the Apple1 directory. The address decoder stays disabled, and the Propeller emulates the Apple-1 ROM (really the Replica-1 ROM with BASIC and Ken Wessen's Krusader), simply to demonstrate that the 6502 works.


The Propeller is not officially 5Volt-tolerant and the MicroKim uses 5V, so this isn't officially supported. 