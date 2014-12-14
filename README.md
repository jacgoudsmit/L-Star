L-Star: Minimal 6502/Propeller computer
=======================================

My <a href=http://github.com/JacGoudsmit/Propeddle>Propeddle project</a> uses a RAM chip and a few glue logic chips to give a Propeller complete control over a 65C02. But if all you want is to emulate a simple 6502 computer such as the Apple-1 that doesn't need ~IRQ, ~NMI, ~RESET, ~SO, RDY or BE, and doesn't need a lot of memory, all of those aren't needed.

The L-Star project (named after the Elstar, which is a delicious apple from the Netherlands :-) is a minimalized version of Propeddle: the glue logic and RAM chip were left out, so the data bus and address bus of the WDC 65C02 are directly connected to the Propeller (as well as the R/~W and PHI2). The Propeller doesn't have any control over the signals (not even ~RESET, but keep reading). Using so many pins for the data bus and address bus doesn't leave enough Propeller pins for color video, but with the 1-pin TV driver it can still generate black-and-white video. I also kept the PS/2 keyboard connected via the usual two pins.

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
<tr><td>P31</td><td>TXD serial port from PC</td></tr>
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

The Github repository contains an emulator for the Apple-1 that works as described in the following sections. I'll be working on emulators for other systems soon; you should see the result probably early 2015.

Clock
-----
The Propeller generates the clock for the 65C02 on the same output as the SCL pin of the EEPROM that stores the Propeller firmware. In order to keep the EEPROM from activating, the Propeller keeps the SDA pin high. The main program sets up a hardware clock that generates a 1MHz clock pulse, and the cogs that emulate the memory and I/O chips wait for the clock pin to go high and low, to synchronize with the 65C02.

Memory Cog
----------
The memory cog is in charge of emulating the ROM and RAM in the system. The main loop of the memory cog works roughly as follows:
<ol>
<li>Wait until the clock goes LOW. This is the start of a new cycle, the 65C02 puts the address on the address bus after a short time.</li>
<li>While the 65C02 sets up the address bus, the Propeller goes off the data bus by switching P0-P7 to input mode. If it put something on the data bus during the previous clock cycle, it will be taken off now, and the required data bus hold time, will be satisfied.</li>
<li>The Propeller reads the pins and checks the R/~W pin to find out whether the 65C02 wants to read or write.</li>
<li>The address is converted to a hub address, and the code checks to make sure that the 65C02 isn't trying to write into a ROM area.</li>
<li>By now, the second half of the clock pulse has arrived. That means the 65C02 is either putting data on the data bus (write mode), or expects to see incoming data by the time the clock goes low again. The memory cog reads or writes the data bus from or to the hub. Then the main loop starts over again.</li>
</ol>

Before the main loop starts, the memory cog performs a similar loop, except it doesn't touch the ROM/RAM areas in the hub, but puts the value 0 onto the data bus for each clock cycle where the 65C02 is in Read mode (R/~W high). Write cycles are ignored. Except in some rare cases that I won't go into here, it will eventually interpret the 0-byte as a BRK instruction, and it will retrieve the IRQ/BRK vector at memory locations $FFFE and $FFFF. When that happens, the memory cog reads the reset vector from the ROM data and sends them to the 65C02, thus simulating a reset. Because of this, in most cases, it will look to the user as if a reset was generated at power-up time; remember the Propeller isn't actually capable of doing this, because the ~RESET line is not connected to the Propeller.

The ROM data that the 65C02 "sees", comes from a binary image file that's inserted into the code at compile time, using the "File" command a DAT area in Spin. The original Apple-1 emulator only had 256 bytes of ROM, containing the Woz monitor. To make the system a little more usable, I used an 8K ROM image file from Ken Wessen's Krusader project, which is an interactive assembler/disassembler that was specifically designed for Vince Briel's Replica 1 project. Besides the Krusader program (the 65C02 version to be precise), it also contains the Apple BASIC ROM image and the Woz Monitor of course.

The RAM is simply an array of bytes in the hub, that follows the ROM data. The Propeller only has a total of 32KB of hub RAM, so the amount of RAM that's available to the 65C02 is limited. For the Apple-1 emulator, a little over 16KB is available. There is a slight problem with this, as the Krusader program assumes by default that the system has 32KB of RAM. So at startup time, the ROM code is patched by the main program to move the symbol table to a different location that falls inside the 16KB limit.

If you would like to use more RAM, it's possible to attach a memory chip such as a 62256 to the address bus, data bus, R/~W and PHI2 pins. You will need a chip that supports 3.3V as power supply, e.g. the Alliance Memory AS6C62256, and some glue logic. You will also need to reconfigure the memory cog so that it doesn't decode the RAM to/from Propeller hub memory anymore. This is as simple as removing the line that declares the byte array that represents the RAM memory: the code is smart enough to determine that when the ram start address is equal to the ram end address, there's never anything to decode as RAM.

PIA Emulator
------------
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

Terminal Functionality
----------------------
When the L-Star runs the Apple-1 emulator firmware, all text input and output happens one character at a time. Because of this, it's pretty easy to emulate the terminal functionality with the serial port: Whenever the 65C02 sends a character to the video output port of the emulated PIA, the Spin code on the Propeller sends the character to the serial port, and whenever the serial port receives a character from the serial port, it emulates a new character on the emulated keyboard port.

Additionally, the Propeller has 3 pins to connect a PS/2 keyboard and a TV. The PS/2 keyboard is connected in the usual way (same schematic as the Propeller Demo board), but for TV output, I used the 1-pin TV output driver from the Parallax Object Exchange (OBEX) and forums. This driver is somewhat... odd, because it generates a three-level analog signal on a single digital pin. It does this by setting the pin to 1 to generate white level, 0 to generate sync/blanking, and a high-frequency clock signal for black. Because the frequency is much higher than regular (standard definition) TV's can handle, they see it as a DC level somewhere between the 0V and 3.3V level. This works surprisingly well, especially on CRT TV's and monitors, but digital LCD TV's may have problems because they may not be happy with the high-frequency signal for black.

So, the TV output may not work for everyone, and not everyone may have a PS/2 keyboard anymore to connect to the project. But the serial port is needed anyway to download the firmware into the Propeller, so if you don't want to use the PS/2 keyboard or the TV output, or if you don't have the connectors, you don't need them. The software doesn't have to be changed if you don't want to use them.

You will need some sort of terminal emulation software on your PC to make the Apple-1 emulation useful. I like TeraTerm Pro to do this. There are various programs available for the Apple-1, most of them can be downloaded in Woz Hex format from places like the forums at brielcomputers.com. You just use the File Transfer option in TeraTerm to upload them to the L-Star. The text in the files that you upload is interpreted as commands by the Woz monitor, and after the download is complete, the RAM in the emulated Apple-1 is filled with a program that you can execute.

Future Plans
------------
At the time of this writing, the L-Star software emulates the Apple-1, but there are probably many other computers that can be emulated with this simple hardware. Those will appear in the Software directory.

I created the schematic and a rudimentary PCB design. I may make a kit out of this, the cost of which should probably be less than $50, but I think I want to change the design so that it's possible to use the three Propeller pins that are currently used for PS/2 keyboard and TV, and use them for other purposes. For example, a KIM-1 emulator may be possible by using an I2C controlled 6-digit 7-segment display. A PET-2001 emulator may be possible by connecting a pin to the ~IRQ and generating a 60Hz pulse. It's possible to connect a PS/2 keyboard with just one pin instead of two (the disadvantage is that you have to hit the space bar to let the Propeller synchronize the clock, and the Caps Lock lights and other lights won't work), and for some purposes it may be interesting to use two or three pins instead of one for video.

I also want to put a step-by-step how-to guide on one of my websites, or in a place like Instructables.com, to make your own L-Star. I'm thinking I want to do this for three versions; the Parallax #32812 or #32212 proto boards, the #32810 USB proto board, and a solderless breadboard. Each of those should be very easy to do even for inexperienced electronics hobbyists.

Good luck, and have fun!
