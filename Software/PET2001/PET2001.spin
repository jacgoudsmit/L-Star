''***************************************************************************
''* PET2001 project for L-Star
''* Copyright (C) 2016 Jac Goudsmit
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
'' This project for the L-Star hardware emulates a Commodore PET-2001.
'' Memory map:
''  $0000-$7FFF: SRAM chip
''  $8000-$83FF: Video RAM
'' ($8400-$8FFF) Reserved
'' ($9000-$9FFF) Reserved for ROM
'' ($A000-$AFFF) Reserved for ROM
'' ($B000-$BFFF) Reserved for Basic 4.0 extensions
''  $C000-$DFFF: BASIC ROM
''  $E000-$E7FF: Editor ROM
'' ($E800-$EFFF) Reserved for I/O devices:
''               $E810-$E81F: PIA 1 (Diagnostics, cassette, keyboard)
''               $E820-$E82F: PIA 2 (IEEE-488)       
''               $E840-$E84F: VIA   (user port, cassette, video)
''               $E880-$E88F: CRTC
''  $F000-$FFFF: Kernal ROM
''
CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  RAMSIZE       = $8000         ' Amount of RAM to map to the SRAM chip                        
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  clock1:       "Clockgen"      ' Clock generator
  video:        "Debug_1pinTV"  ' Video  
  sram:         "SRAMCtrl"      ' SRAM control
  screenram:    "Memory"        ' Screen RAM                       
  rom1:         "Memory"        ' ROM emulation

  
PUB main | screenptr

  ' Wait a second to give user a chance to connect serial terminal
  'waitcnt(clkfreq + cnt)

  ' Init video, get pointer to video buffer
  screenptr := video.Start(hw#pin_TV)

  ' Initialize the clock before starting any cogs that wait for it
  clock1.Init(1_000_000)

  ' Start the screen cog
  screenram.StartEx(screenptr, screenptr, screenptr + 1024, $8000, 0)

  ' Start the ROM cogs
  rom1.StartEx(@Rom1Start, @Rom1End, @Rom2End, $C000, 0) 
  'rom1.StartEx(@TestRomStart, @TestRomEnd, @TestRomEnd, $FFF0, 0)

  ' Start the SRAM cog
  sram.Init(RAMSIZE)
  sram.Start
  
  video.str(string("Reset the 6502 to start.", 13, 13))
  video.gotoxy(0,25) ' Put the cursor off the screen
  
  ' Start the clock
  clock1.Activate

  ' Stay busy
  repeat
    screenptr := 0

DAT

Rom1Start
                        File    "basic-2-c000.901465-01.bin" ' $C000-$CFFF
                        File    "basic-2-d000.901465-02.bin" ' $D000-$DFFF
                        File    "edit-2-n.901447-24.bin"     ' $E000-$E7FF
Rom1End
                        byte    $00[$800]                    ' $E800-$EFFF - I/O goes here later 
Ram1End                        

Rom2Start
                        File    "kernal-2.901465-03.bin"     ' $F000-$FFFF
Rom2End

TestRomStart
                        '        00,  01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
                        byte    $EE, $00, $80, $4C, $F0, $FF, $00, $00, $00, $00, $F0, $FF, $F0, $FF, $F0, $FF  
TestRomEnd
                                                
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