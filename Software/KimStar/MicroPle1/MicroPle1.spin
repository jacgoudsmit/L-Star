''***************************************************************************
''* L-STAR, Kimple1: Apple-1 ROM and Apple-1 PIA emulator for MicroKim 
''* Copyright (C) 2014 Jac Goudsmit
''***************************************************************************

CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  BAUDRATE      = 115200        ' Baud rate on serial port
  RAM_SIZE      = 16384         ' Change this to 0 if external RAM attached
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  term:         "FullDuplexSerial" ' Serial terminal
  mem:          "Memory"        ' ROM/RAM emulator for Apple-1 ROM
  kim:          "Memory"        ' ROM/RAM emulator for KIM-1 ROM
  pia:          "A1PIA"         ' PIA hardware emulator  

PUB main | i

  ' Init serial, keyboard and TV
  term.Start(hw#pin_RX, hw#pin_TX, 0, BAUDRATE)
  term.str(string(16,"L-STAR MICROPLE-1 ;-)",13,10,"(C) 2015 JAC GOUDSMIT",13,10))

  ' Patch the ROM
  Patch($F009,$10)                                      ' Krusader assumes 32K RAM, this changes a table location from 7C00 to 1000
  Patch($FF2E,$08)                                      ' Let Woz monitor use backspace instead of _ for correction                        

  ' Patch the reset vector to boot into the KIM ROM.
  ' Comment this out to start Woz mon on bootup
  ' In KIM mode, type AD F F 0 0 GO on the keyboard to run Woz mon
  ' In Woz mon, type 1C22R to start KIM 
  Patch($FFFC,$22)
  Patch($FFFD,$1C)
  
  ' Start the Address Decoder cog
  cognew(@DenCog, @@0)
  
  ' Start the PIA emulator
  pia.Start($D010)

  ' Start KIM ROM cog
  kim.StartEx(@KimRom, @KimRomEnd, @KimRomEnd, $1800, 0)
      
  ' Start the memory cog
  mem.Start(@RomFile, @RomEnd, @RomEnd)

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

KimRom
                        File    "6530-003.bin"
                        File    "6530-002.bin"
KimRomEnd
                        
DAT

                        org 0
DenCog
                        mov     DIRA, mask_DEN
                        mov     OUTA, mask_DEN

DenLoop
                        waitpne mask_CLK0, mask_CLK0    ' Wait until clock goes low
                        or      OUTA, mask_DEN
                        mov     addr, INA

                        and     addr, mask_ADDR
                        cmp     addr, mask_MAX wc
                        
        if_c            andn    OUTA, mask_DEN          ' Turn address decoder on if it matches
                        waitpeq mask_CLK0, mask_CLK0    ' Wait until clock goes high
                        jmp     #DenLoop                                                            
                                                
addr                    long    0

mask_DEN                long    (|<hw#pin_DEN)
mask_CLK0               long    (|<hw#pin_CLK0)
mask_ADDR               long    (|<hw#pin_A15) | (|<hw#pin_A14) | (|<hw#pin_A13) | (|<hw#pin_A12) | (|<hw#pin_A11) | (|<hw#pin_A10)
mask_MAX                long    (%000110 << hw#pin_A10) 
                                                                                                
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