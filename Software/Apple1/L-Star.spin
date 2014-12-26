''***************************************************************************
''* L-STAR, Apple-1 replica with minimal hardware
''* Copyright (C) 2014 Jac Goudsmit
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
''
'' A PS/2 keyboard can be connected to the usual pins P26-P27, in the same
'' way as on the Propeller Demo board. There aren't enough pins for a full
'' TV output, but we can use the 1-pin TV driver from the Parallax Forums
'' to generate a monochrome video signal. The clock signal for the 65C02 is
'' generated on the same pin as the SCL clock signal to the EEPROM; this
'' won't harm the EEPROM as long as we keep SDA high.
''
'' The code that runs on the Propeller emulates ROM and RAM in the hub. But
'' because there's not enough space in the hub, the amount of ROM and RAM
'' that are available are limited. It's possible to connect an SRAM chip
'' (e.g. a 62256) to the bus, and turn the RAM emulation off, to overcome
'' this problem.  
CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  BAUDRATE      = 115200        ' Baud rate on serial port
  RAM_SIZE      = 16384         ' Change this to 0 if external RAM attached
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  clock:        "Clock"         ' Clock generator
  term:         "SerKbd1TV"     ' Serial/Keyboard/TV terminal
  mem:          "Memory"        ' ROM/RAM emulator
  pia:          "A1PIA"         ' PIA hardware emulator  

VAR
  byte  MyCogId                 ' Cog ID + 1
  
PUB main | i

  ' Init serial, keyboard and TV
  term.Start(hw#pin_RX, hw#pin_TX, hw#pin_KBDATA, hw#pin_KBCLK, hw#pin_TV, BAUDRATE)
  term.str(string("L-STAR (C) 2014 JAC GOUDSMIT",13,13,"HUB RAM BYTES: "))
  term.dec(RAM_SIZE)
  term.str(string(13,"SIM.ROM BYTES: "))
  term.dec(@RomEndRamStart-@RomFile)
  term.str(string(13,13))

  ' Patch the ROM
  Patch($F009,$3C)                                      ' Krusader assumes 32K RAM, this changes a table location from 7C00 to 3C00
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
                        File    "65C02.rom.bin"         ' BASIC/Krusader/WOZ mon for 65C02
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