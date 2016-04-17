''***************************************************************************
''* L-STAR, Apple-1 replica with minimal hardware
''* Copyright (C) 2014 Jac Goudsmit
''*
''* Modified to work on a QuickStart connected to a MicroKim
''***************************************************************************
CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  BAUDRATE      = 115200        ' Baud rate on serial port
  RAM_SIZE      = 16384         ' Change this to 0 if external RAM attached
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  term:         "FullDuplexSerial" ' Serial terminal
  mem:          "Memory"        ' ROM/RAM emulator
  pia:          "A1PIA"         ' PIA hardware emulator  

PUB main | i

  ' Init serial, keyboard and TV
  term.Start(hw#pin_RX, hw#pin_TX, 0, BAUDRATE)
  term.str(string(16,"L-STAR (C) 2014 JAC GOUDSMIT READY",13,10))

  ' Patch the ROM
  Patch($F009,$3C)                                      ' Krusader assumes 32K RAM, this changes a table location from 7C00 to 3C00
  Patch($FF2E,$08)                                      ' Let Woz monitor use backspace instead of _ for correction                        

  DIRA[hw#pin_DEN]~~
  OUTA[hw#pin_DEN]~~ ' Disable on-board address decoder

  ' Start the PIA emulator
  pia.Start($D010)
    
  ' Start the memory cog
  mem.Start(@RomFile, @RomEndRamStart, @RamEnd)

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