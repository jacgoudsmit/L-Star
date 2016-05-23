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
''
'' NOTE: This version of the Apple 1 Replica project on the L-Star hardware
'' uses the SRAM chip for storage. To do this, one extra pin is required,
'' compared to the standard Apple1 project (which uses a Memory cog for RAM
'' and ROM). To do this, the PS/2 keyboard driver needed to be replaced with
'' the 1-pin keyboard driver. 
CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  RAMSIZE       = 8192          ' Amount of RAM emulated by Propeller                        
  BAUDRATE      = 115200        ' Baud rate on serial port
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  clock1:       "Clock"         ' Clock generator
  term:         "SerKbd1TV"     ' Serial/Keyboard/TV terminal
  sram:         "SRAMCtrl"      ' SRAM control
  rom:          "Memory"        ' ROM emulation                        
  pia:          "A1PIA"         ' PIA hardware emulator  

PUB main | i

  ' Wait a second to give user a chance to connect serial terminal
  waitcnt(clkfreq + cnt)
  
  ' Init serial, keyboard and TV
  term.Start(hw#pin_RX, hw#pin_TX, -1 {hw#pin_KBDATA}, hw#pin_TV, BAUDRATE)
  term.str(string("L-STAR (C) 2014-2016 JAC GOUDSMIT",13))
  term.str(string("SIM.ROM BYTES: "))
  term.dec(@RomEnd-@RomFile)
  term.str(string(13,13))

  ' Initialize the clock before starting any cogs that wait for it
  clock1.Init(1_000_000)
    
  ' Start the PIA emulator
  pia.Start($D010)

  ' Start the memory cog
  rom.Start(@RomFile, @RomEnd, @RamEnd)

  ' Start the SRAM cog
  sram.Init(0)
  sram.AddRam(RAMSIZE, 32768 - RAMSIZE)
  sram.Start
  
  term.str(string("Activate!",13))
  
  ' Start the clock
  clock1.Activate

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

  byte[addrval + @RomEnd - $1_0000] := dataval 

DAT

RomFile
                        File    "65C02.rom.bin"         ' BASIC/Krusader/WOZ mon for 65C02
RomEnd
                        byte    $A7[RAMSIZE]
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