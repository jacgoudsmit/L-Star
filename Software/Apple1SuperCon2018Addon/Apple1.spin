''***************************************************************************
''* L-STAR, Apple-1 replica with minimal hardware
''* Copyright (C) 2014-2018 Jac Goudsmit
''*
''* Some of the code in this project was based on the following projects,
''* all under MIT license unless otherwise mentioned:
''* "Krusader"        (C) 2007-2014 Ken Wessen (license unclear(*))
''* "Prop-6502",      (C) 2009 Dennis Ferron
''* "Propeddle",      (C) 2011-2014 Jac Goudsmit
''* "Replica 1",      (C) 2004-2014 Vince Briel
''* "Superboard III", (C) 2013-2014 Vince Briel and Jac Goudsmit
''* "1-Pin TV",       (C) 2009-2014 Eric Ball, Ray Rodrick, Marko Lukat
''*
''* (*) Ken Wessen wrote his Krusader assembler/disassembler for the 6502
''* specifically for the Brielcomputers Replica-1, and it has been used in
''* other projects too, but there is no specific license mentioned on his
''* website or in the source code, so I assume it's public domain.
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' This little project is a proof-of-concept that shows that a Propeller and
'' a WDC 65C02 are enough to emulate/replicate an Apple 1. 
''
'' The Propeller generates a 1MHz clock signal to the PHI2 input of the
'' 65C02, and it reads the address bus to find out where the 65C02 wants to
'' read or write data. It manipulates the data bus to emulate RAM, ROM and
'' I/O devices.
''
'' The !NMI, !IRQ, !SO and RDY pins are pulled high. The Reset pin is pulled
'' high but has a pushbutton switch to ground.

CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  BAUDRATE      = 115200        ' Baud rate on serial port
  BADGEBAUDRATE = 19200         ' Baud rate on badge serial port                        
  RAM_SIZE      = 20*1024       ' Change this to 0 if external RAM attached

OBJ
  hw:           "Hardware"      ' Constants for hardware
  clock:        "Clockgen"      ' Clock generator
  term:         "SuperConBadge" ' Prop Plug and SuperCon Badge
  mem:          "Memory"        ' ROM/RAM emulator
  pia:          "A1PIA"         ' PIA hardware emulator  

VAR
  byte  MyCogId                 ' Cog ID + 1
  
PUB main | i

  ' Init serial, keyboard and TV
  term.Start(BAUDRATE, BADGEBAUDRATE)
  term.str(string("L-STAR (C) 2014-2018 JAC GOUDSMIT",13,13,"HUB RAM BYTES: "))
  term.dec(RAM_SIZE)
  term.str(string(13,"SIM.ROM BYTES: "))
  term.dec(@RomEndRamStart-@RomFile)
  term.str(string(13,13))

  ' Patch the ROM
  Patch($F009,$4C) 'TODO: Calculate                     ' Krusader assumes 32K RAM, this changes a table location
  Patch($FF05,$13)                                      ' Redirect STY $D012 to $D013 to prevent degree-symbol on terminal
  Patch($FF2E,$08)                                      ' Let Woz monitor use backspace instead of _ for correction                        

  ' Initialize the clock before starting any cogs that wait for it
  clock.Init(1_000_000)
    
  ' Start the PIA emulator
  pia.Start($D010)
    
  ' Start the memory cog
  mem.Start(@RomFile, @RomEndRamStart, @RamEnd)

  ' Start the clock
  clock.Activate

  ' The following infinite loop emulates the terminal part of the machine.
  ' If a key has come in from the serial port or keyboard, it's made available to the PIA emulator;
  ' If the 6502 has written a character to the PIA, send it to the screen and the serial port.
  ' NOTE: The Prop Plug is configured for 115200. When sending a long file to the Apple 1
  ' emulator (e.g. a basic listing or a hex file), it can easily get overwhelmed. You will
  ' probably want to us a slower speed or add character delays and line delays to prevent this.
  ' One day I hope to find some time to implement flow control in the PIA emulator module.
  repeat
    i := term.rxcheck
    if i <> -1
      pia.SendKey(i)
      
    i := pia.RcvDisp
    if i => 0
      if (i < 32) or (i > 126)
        term.str(string(32,8))
      term.tx(i)

PRI Patch(addrval, dataval)

  byte[addrval + @RomEndRamStart - $1_0000] := dataval 

DAT

RomFile
                        ' Uncomment the ROM image that you want to load.
                        ' You can only use a single ROM image at a time!

                        ' This ROM image came from the website of Ken Wessen who wrote
                        ' Krusader, an interactive editor and assembler that you can use
                        ' to write 6502 assembly programs.
                        ' See http://school.anhb.uwa.edu.au/personalpages/kwessen/apple1/Krusader.htm
                        ' To run Krusader from Woz Mon, enter F000R 
                        ' The image also contains the BASIC interpreter written by Steve Wozniak,
                        ' which is simple but has a few quirks. For example it doesn't support
                        ' arrays or floating point, and it gives an error when you
                        ' enter a line into the BASIC program that has a syntax error
                        ' but also when execution falls out of a program without
                        ' encountering an END instruction.
                        ' To start the BASIC interpreter, enter E000R
                        ' NOTE: Because the Woz basic interpreter tries its best to make the
                        ' listing of a program look as readable as possible, you can't record
                        ' a listing on your terminal emulator and then play it back to load it
                        ' again. To save a BASIC program you have to drop to Woz Mon and dump
                        ' the RAM that's in use by the BASIC program.                                                                            
                        File    "65C02.rom.bin"         ' BASIC/Krusader/WOZ mon for 65C02

                        ' This ROM was copied from another location that I don't remember.
                        ' I think it was pointed out to me on either the Brielcomputers forum or
                        ' the 6502.org forums.
                        ' The image contains Woz mon of course, as well as Krusader (I'm not sure
                        ' if this has the 65C02 version of Krusader or the 6502 version),
                        ' but it also has a version of Microsoft Basic that was ported from
                        ' the Apple 2 to the Apple 1.
                        ' This will allow you to run many programs (e.g. from the "101 BASIC Games"
                        ' book by David Ahl) that depend on features such as arrays and floating
                        ' point variables. You also get the usual MS-BASIC features such as the
                        ' ability to use the question mark instead of PRINT.
                        ' Another feature is that a LIST from Microsoft BASIC is formatted the
                        ' exact same way as how you would add program lines into a program.
                        ' So all you need to do to save a program is enable logging in your
                        ' terminal program and enter LIST. At the end of the list, turn logging off
                        ' and remove the LIST command and the OK prompt from the output file,
                        ' that's it. Next time you want to load the program, just type NEW to
                        ' make sure there's nothing already in memory, then replay the file
                        ' from the terminal program.
                        'File    "AppleSoftBasic.rom.bin"' AppleSoft/Microsoft BASIC/Krusader/WOZ mon
RomEndRamStart
                        ' The RAM must immediately follow the ROM
                        byte    $EA[RAM_SIZE]
RamEnd                        
                                                
CON     
''***************************************************************************
''*
''* Permission is hereby granted, free of charge, to any person obtaining a
''* copy of this software and associated documentation files (the
''* "Software"), to deal in the Software without restriction, including
''* without limitation the rights to use, copy, modify, merge, publish,
''* distribute, sublicense, and/or sell copies of the Software, and to permit
''* persons to whom the Software is furnished to do so, subject to the
''* following conditions:
''*
''* The above copyright notice and this permission notice shall be included
''* in all copies or substantial portions of the Software.
''*
''* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
''* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
''* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
''* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
''* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
''* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
''* THE USE OR OTHER DEALINGS IN THE SOFTWARE.
''***************************************************************************