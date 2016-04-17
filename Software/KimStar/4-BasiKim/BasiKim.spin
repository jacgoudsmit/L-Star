''***************************************************************************
''* L-STAR, BasiKim: MS-BASIC and RAM expansion for MicroKim 
''* Copyright (C) 2016 Jac Goudsmit
''***************************************************************************
''
'' This project is intended as a proof of concept to attach a Propeller to
'' a MicroKim and make it emulate a preloaded Microsoft Basic in memory at
'' address $2000 (NOTE: startup address is $4065, see the documentation).
'' Of course you don't HAVE to start BASIC, you can just use this as a RAM
'' expansion that happens to be pre-loaded with a BASIC interpreter
'' whenever you restart the Propeller. In other words: the virtual RAM that
'' is represented by the Propeller running this software, is persistent
'' across 6502 resets, but NOT across Propeller resets!
''
'' It also provides extra RAM which is needed to load BASIC programs. The
'' easiest way to load a BASIC source code file into memory is to use a
'' good terminal emulator such as TeraTerm or PuTTY, with the MicroKim
'' serial port (not the Propeller serial port; you need that only for
'' downloading the firmware to the Propeller), and tell it to send a file.
'' Make sure you set your terminal program to add a character delay and a
'' line delay when you send a BASIC source file: the interpreter needs time
'' at the end of each line to tokenize the BASIC commands. I've had good
'' experience with the following settings:
'' * 2400bps 8 databits 1 stopbit no parity
'' * 8ms character delay
'' * 400ms line delay 
''
'' The serial port on the Propeller doesn't have a function for this project
''
'' PLEASE READ THE MICROSOFT DOCUMENTATION. This early BASIC is a little
'' weird, for example the line editor uses '_' instead of backspace and
'' '@' to restart a line from the beginning. Also, you may have to patch
'' the code to use Ctrl+C to break out of a program.

CON
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  BAUDRATE      = 115200        ' Baud rate on serial port
  RAMSIZE       = 24576         ' Plenty of space for Star Trek :) (MS recommends at least 16K)
  LOADADDRESS   = $2000         ' Start of memory mapping in 6502 address space
  
OBJ
  hw:           "Hardware"      ' Constants for hardware
  mem:          "Memory"        ' ROM/RAM emulator for BASIC and RAM expansion

PUB main

  ' Start the Address Decoder cog
  cognew(@DenCog, @@0)

  ' Example for a patch to detect Ctrl+C to break out of execution of a
  ' BASIC program, as mentioned in the documentation. This patch has
  ' already been applied to the image.
  'Patch($26E3, $A9)
  'Patch($26E4, $03)
  'Patch($26E5, $18)
    
  ' Start the memory cog
  mem.StartEx(@RomStart, @RomEnd, @RamEnd, LOADADDRESS, 0)

  ' All needed cogs are running, we have nothing else to do.
  cogstop(cogid)

  
PRI Patch(addrval, dataval)

  byte[addrval + @RomStart - LOADADDRESS] := dataval 

DAT

RomStart
                        ' MS-BASIC for the KIM-1 was originally distributed on
                        ' cassette, and loaded into RAM (see documentation).
                        ' It may be possible to make the MS BASIC image
                        ' read-only; to do so, move the "file" command here.  
RomEnd
RamStart                ' RAM always follows immediately after ROM, see Memory module

                        ' Preload MS-Basic in simulated RAM
                        ' I got this image file from Hans Otten's website
                        ' (http://retro.hansotten.nl). Bedankt Hans! :)
                        file    "KB9.bin"
                        
                        ' The user RAM must immediately follow the BASIC image file
                        ' This is used for BASIC programs and data.
                        ' Basic is a little over 8K long, MS says you need at least
                        ' 16K of RAM starting at $2000.
                        byte    $EA[RAMSIZE - ($ - @RamStart)]                        
RamEnd
                        
                        
DAT

                        org 0
DenCog
                        mov     DIRA, mask_DEN
                        mov     OUTA, mask_DEN

DenLoop
                        waitpne mask_CLK0, mask_CLK0    ' Wait until clock goes low
                        or      OUTA, mask_DEN
                        mov     addr, INA

                        ' Map the on-board hardware for addresses $0000-$1FFF
                        and     addr, mask_ADDR
                        cmp     addr, mask_MAX wc

                        ' The ROM should also be mapped at $F800-$FFFF
                        ' so that the reset and interrupt vectors are retrieved from it
                        ' Comment this out if you want to map your own ROM at the
                        ' top of memory.
        if_nc           cmp     mask_HIGHAREA, addr wc
                        
        if_c            andn    OUTA, mask_DEN          ' Turn address decoder on if it matches
                        waitpeq mask_CLK0, mask_CLK0    ' Wait until clock goes high
                        jmp     #DenLoop                                                            
                                                
addr                    long    0

mask_DEN                long    (|<hw#pin_DEN)
mask_CLK0               long    (|<hw#pin_CLK0)
mask_ADDR               long    hw#con_mask_ADDR
mask_MAX                long    ($2000 << hw#pin_A0)
mask_HIGHAREA           long    ($F800 << hw#pin_A0)    ' Can probably be ($FFFA << hw#pin_A0)

                                                                                                
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