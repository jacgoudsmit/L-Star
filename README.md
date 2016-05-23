L-Star: Minimal 6502/Propeller computer
=======================================

The L-Star is an open-source single-board computer design that uses a Propeller to control a 6502 processor. You can use it to emulate early 6502 based computers such as the Apple-1 or the OSI Challenger, or you can invent your own 6502 computer.

All the parts that are needed to put an L-Star together are available as through-hole, so you can build it on a breadboard or on a Propeller proto board. You can also get it as a kit called the L-Star Plus, which has some extra features such as a 128KB SRAM chip and an expansion port.

History
-------
At the end of 2014, I saw a video by Ben Heckendorn, in which he <a href=https://www.youtube.com/watch?v=ZXllm5JWWAs>built an Apple-1 replica</a> (based on Vince Briel's <a href=http://www.brielcomputers.com/wordpress/?cat=17>Replica 1 project</a>). In the video, Ben casually remarks that he could have probably left the PIA (Peripheral Interface Adapter) chip out of the design and used the Propeller to replace it, but he didn't want to bother writing the code to do that. As it happened, I had already written some code to do that for my <a href=https://github.com/JacGoudsmit/Propeddle>Propeddle project</a>, so I wondered if it would be possible to go even further and remove not only the PIA, but also the RAM chip.

I named the result L-Star, after the Elstar, which is a delicious apple variety from the Netherlands. The electronic design is a minimalized version of Propeddle: I removed the glue logic and RAM chip, so the data bus and address bus of the Western Design Center W65C02S are directly connected to the Propeller (as well as the R/W and Clock pins). This is the minimum set of pins on the 6502 that the Propeller needs to control, in order to replicate a 6502 computer such as the Apple-1; however, with that many Propeller pins in use, there aren't enough other Propeller pins available to generate color video, so I used the 1-pin TV driver to generate black-and-white NTSC or PAL compatible video. A PS/2 keyboard can also be connected. Both keyboard and video are optional for the Apple-1 replica; you can use a terminal emulator on the Propeller's serial port instead).

The first version of L-Star was built on an old Parallax Propeller USB proto board, the kind that had the Propeller smack-dab in the middle of the board and doesn't leave a lot of room for any big chips (they're no longer sold). In December 2014 I took that with me on a business trip but unfortunately it stopped working. I bought a <a href=https://www.parallax.com/product/32305>Propeller Education Kit</a> and used it to re-create the project on breadboards. Later on, I also built L-Star on the newer <a href=https://www.parallax.com/product/32810>Propeller USB Project Board</a>.

I also designed a custom printed circuit board (PCB) in Kicad. I called this L-Star Plus because it has a 128KB SRAM chip added to it, as well as an expansion port and a power supply. All the parts on the PCB are through-hole, so it's easy to solder the project together. And you can get all the parts from Mouser including the 65C02 and the Propeller. At the time of this writing, Mouser even stocks the Prop Plug which you need to connect the Propeller (and thus the L-Star project) to a USB port of a computer.

How it works
------------
### Connections
Here's how the Propeller is connected:
<table>
<tr><th>pin</th><th>function</th></tr>
<tr><td>P0-P7</td><td>Data bus D0-D7 to/from 65C02</td></tr>
<tr><td>P8-P23</td><td>Address bus A0-A15 from 65C02</td></tr>
<tr><td>P24</td><td>R/~W from 65C02</td></tr>
<tr><td>P25</td><td>Optional 1-pin TV out, connected to RCA socket via 270 ohm resistor</td></tr>
<tr><td>P26-P27</td><td>Optional PS/2 keyboard, connected to Mini-DIN with the usual 2x100R, 2x10K resistors</td></tr>
<tr><td>P28</td><td>EEPROM SCL; PHI2 clock to 65C02</td></tr>
<tr><td>P29</td><td>EEPROM SDA</td></tr>
<tr><td>P30</td><td>TXD serial port to PC</td></tr>
<tr><td>P31</td><td>RXD serial port from PC</td></tr>
</table>

Other 65C02 pins:
<table>
<tr><th>pin</th><th>function</th></tr>
<tr><td>VPB</td><td>(Vector Pull out) not connected</td></tr>
<tr><td>RDY</td><td>(Ready) pulled high via 3k3 resistor</td></tr>
<tr><td>PHI1O</td><td>(Inverted clock out) not connected</td></tr>
<tr><td>IRQB</td><td>(Interrupt request) pulled high via 3k3 resistor</td></tr>
<tr><td>MLB</td><td>(Memory lock out) not connected</td></tr>
<tr><td>NMIB</td><td>(Non-maskable Interrupt) pulled high via 3k3 resistor</td></tr>
<tr><td>SYNC</td><td>(Instruction pull out) not connected</td></tr>
<tr><td>A0-A15</td><td>(Address bus) connected to Propeller P8-P23</td></tr>
<tr><td>D0-D7</td><td>(Data bus) connected to Propeller P0-P7</td></tr>
<tr><td>RWB</td><td>(Read/Not Write) connected to Propeller P24</td></tr>
<tr><td>BE</td><td>(Bus Enable) pulled high via 3k3 resistor</td></tr>
<tr><td>PHI2</td><td>(Clock in) connected to Propeller P28</td></tr>
<tr><td>SOB</td><td>(Set Overflow) pulled high via 3k3 resistor</td></tr>
<tr><td>PHI2O</td><td>(Clock out) not connected</td></tr>
<tr><td>RESB</td><td>(Reset) pulled high via 3k3 resistor, connected to tact switch connected to GND for reset</td></tr>
</table>

On the L-Star Plus design, the Propeller can control the Chip-Enable-Not pin via P27, if you want to connect the PS/2 keyboard, you have to use the 1-pin PS/2 keyboard driver which makes it necessary to ask the user to hit a key to measure the timing, and which makes it impossible to control the lights on the keyboard.

### Clock
The Propeller generates the clock for the 65C02 on the same output as the SCL pin of the EEPROM that stores the Propeller firmware. In order to keep the EEPROM from activating, the Propeller holds the SDA pin high. The main program sets up a hardware clock that generates clock pulse at up to 1MHz, and the cogs that emulate the memory and I/O chips wait for the clock pin to go high and low, to synchronize with the 65C02.

### Memory Cog
The memory cog is in capable of emulating ROM and/or RAM in the system. The main loop of the memory cog works roughly as follows:
<ol>
<li>Wait until the clock goes LOW. This is the start of a new cycle, the 65C02 puts the address on the address bus after a short time.</li>
<li>While the 65C02 sets up the address bus, the Propeller goes off the data bus by switching P0-P7 to input mode. If it put something on the data bus during the previous clock cycle, it will be taken off now, and the required data bus hold time, will be satisfied.</li>
<li>The Propeller reads the pins and checks the R/~W pin to find out whether the 65C02 wants to read or write.</li>
<li>The address is converted to a hub address, and the code checks to make sure that the 65C02 isn't trying to write into a ROM area.</li>
<li>By now, the second half of the clock pulse has arrived. That means the 65C02 is either putting data on the data bus (write mode), or expects to see incoming data by the time the clock goes low again. The memory cog reads or writes the data bus from or to the hub. Then the main loop starts over again.</li>
</ol>

Before the main loop starts, the memory cog can perform a slightly modified function: instead of letting the 65C02 read from and write to hub memory, it puts the value 0 onto the data bus for each clock cycle where the 65C02 is in Read mode (R/~W high). Write cycles are ignored. Except in some rare cases that I won't go into here, the 65C02 will eventually interpret the 0-bytes on the data bus as a BRK instruction, and it will retrieve the IRQ/BRK vector at memory locations $FFFE and $FFFF. When that happens, the memory cog reads the reset vector from the ROM data and sends it to the 65C02 instead of the IRQ vector, thus simulating a reset. Because of this, in most cases, it will look to the user as if a reset was generated at power-up time; remember the Propeller isn't actually capable of generating a reset, because the ~RESET line is not connected to the Propeller. But this will do, in most cases. And in other cases, the user will still have the Reset button.

The ROM data that the Propeller presents to the 65C02, comes from a binary image file that can be inserted into the code at compile time, using the "File" command in a DAT area in Spin. The original Apple-1 emulator only had 256 bytes of ROM, containing the Woz monitor. To make the system a little more usable, I used an 8K ROM image file from Ken Wessen's Krusader project, which Vince Briel also used for the Replica 1. Krusader is an interactive assembler/disassembler that was specifically designed for the Replica 1. Besides the Krusader program (the 65C02 version to be precise), it also contains the Apple BASIC ROM image and the Woz Monitor of course. If you want to use a different ROM image, you can simply replace the File command; the firmware will always map the ROM image at the top of 65C02 address space, so if you put 256 bytes in a ROM file, the 65C02 will see the ROM bytes at $FF00-$FFFF; if you put a ROM file that's 4KB, it will be at $F000-$FFFF etc.

The RAM is simply an array of bytes in the hub, that follows the ROM data. The Propeller only has a total of 32KB of hub RAM, so the amount of RAM that's available to the 65C02 is limited. For the Apple-1 emulator without the SRAM chip, about 16KB is available. There is a slight problem with this, as the Krusader program assumes by default that the system has 32KB of RAM. So at startup time, the ROM code is patched by the main program to move the symbol table to a different location that falls inside the 16KB limit. If you want to use a different ROM image, make sure you delete the patches! The version of the Apple-1 emulator that uses the SRAM chip to emulate the RAM doesn't have this problem.

### Apple 1 PIA Emulator
I already had code to emulate the Apple-1 PIA on the Propeddle, I just needed to modify it so it doesn't depend on the glue logic. From the point of view of the 65C02, the following functions are needed:
<table>
<tr><th>Address</th><th>Operation</th><th>Function</th></tr>
<tr><td rowspan=2>$D010</td><td>Read</td><td>Gets the ASCII code of the last key pressed, with the most significant bit (msb) set. Whenever the 65C02 reads a value from this location, the msb at location $D011 is reset.</td></tr>
<tr><td>Write</td><td>(ignored)</td></tr>
<tr><td rowspan=2>$D011</td><td>Read</td><td>The msb at this location is set to 1 whenever a new value is available at location $D010. The msb is reset to 0 whenever $D010 is read.</td></tr>
<tr><td>Write</td><td>(ignored)</td></tr>
<tr><td rowspan=2>$D012</td><td>Read</td><td>Reads the byte that was last stored at this location by the 65C02. The msb is reset as soon as the video hardware has processed the byte that was previously written.</td></tr>
<tr><td>Write</td><td>A byte that's stored here with the msb set to 1 is sent to the video hardware. When the video hardware has processed the byte, it resets the msb when the 65C02 reads the location back.</td></tr>
<tr><td rowspan=2>$D013</td><td>Read</td><td>Ignored (mapped for compatibility; the real PIA has a configuration register here)</td></tr>
<tr><td>Write</td><td>Ignored (mapped for compatibility; the real PIA has a configuration register here)</td></tr>
</table>

The code that implements the functionality of the PIA actually cheats a little bit. The Propeller runs at 80MHz and the 65C02 runs at 1Mhz, so there are only 80 clock cycles on the Propeller available for each 65C02 clock cycle. Most Propeller instructions take 4 Propeller cycles, so there is time for about 20 instructions on the Propeller for each clock cycle on the 65C02. However, to perform the extra functionality of setting and resetting bits when the 65C02 accesses the "special" registers in the emulated PIA, more time is needed. The PIA emulator actually takes two 65C02 clock cycles to perform most operations. From the 65C02's point of view, everything still works as expected, but whenever it accesses one of the PIA locations during one clock cycle, the PIA emulation code won't be "listening" for access during the next cycle. But the chance that the 65C02 needs to access any PIA location during two consecutive clock cycles is as good as zero, so that's okay.

### Terminal Functionality
When the L-Star runs the Apple-1 emulator firmware, all text input and output happens one character at a time. Because of this, it's pretty easy to emulate the terminal functionality with the serial port: Whenever the 65C02 sends a character to the video output port of the emulated PIA, the Spin code on the Propeller sends the character to the serial port, and whenever the serial port receives a character from the serial port, it emulates a new character on the emulated keyboard port.

With so many Propeller pins in use for the address bus, data bus and other stuff, there are only 3 pins left to connect an optional PS/2 keyboard and a TV. The PS/2 keyboard is connected in the usual way (same schematic as the Propeller Demo board), but for TV output, I used the 1-pin TV output driver from the Parallax Object Exchange (OBEX) and forums. This driver is somewhat... odd, because it generates a three-level analog signal on a single digital pin. It does this by setting the pin HIGH to generate white level, LOW to generate sync/blanking, and connecting a high-frequency clock signal for black. Because the black-level signal frequency is much higher than what regular (standard definition) TV's can handle, they see it as a DC level somewhere between the blanking and white levels, which is exactly what we want (more information is in the source code for the driver, which is included in the L-Star project). This works surprisingly well, especially on CRT TV's and monitors, but digital LCD TV's may have problems because they may not be happy with the high-frequency signal for black.

So, the TV output may not work for everyone, and not everyone may have a PS/2 keyboard to connect to the project. But the serial port is needed anyway to download the firmware into the Propeller, so if you don't want to use the PS/2 keyboard or the TV output, or if you don't have (or want to buy) the connectors, you don't need them. The software doesn't have to be changed if you don't want to use the keyboard or TV-output.

You will need some sort of terminal emulation software on your PC to make the Apple-1 emulation useful. The serial port settings should be 115200 bps, 8 bits per character, 1 stopbit, no parity, no handshaking. I recommend Tera Term. There are various programs available for the Apple-1 from places such as the forums at brielcomputers.com, most of them can be downloaded in Woz Hex format. You just use the File Transfer option in TeraTerm to upload them to the L-Star. The text in the files that you upload is interpreted as commands by the Woz monitor, and after the download is complete, the RAM in the emulated Apple-1 is filled with a program that you can execute. You will have to change the serial port settings in TeraTerm to give the L-Star extra time to process characters and lines of input. My experience is that 8 milliseconds per character and 400 milliseconds per line works in most cases. It may be possible to reduce these times in some cases but I'll leave that to you (ironically, if you're impatient enough to make your programs download faster, you will have to spend more time to tweak the settings. Such is life...)
