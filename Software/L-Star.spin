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
''* "1-Pin TV",       (C) 2009-2010 Eric Ball, Ray Rodrick
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
'' TV output, but we can use Ray Rodrick's 1-pin TV driver to generate a
'' monochrome video signal. The clock signal for the 65C02 is generated on
'' the same pin as the SCL clock signal to the EEPROM; this won't harm the
'' EEPROM as long as we keep SDA high.
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
  hw:   "Hardware"              ' Constants for hardware
  tv:   "1pinTV256"             ' TV text output
  term: "SerKbdTerm"            ' Serial/Keyboard/TV terminal
  font: "Font_ATARI"            ' Text font
  pia:  "A1PIA"                 ' PIA hardware emulator  

PUB main | i, screen_ptr

  ' Initialize the clock and SDA pins as output, and set them both high for now,
  ' so that the 6502 access cogs can ready themselves by waiting for CLK0 to go low.
  dira[hw#pin_SDA]~~                                    ' The SDA pin must remain high so the EEPROM doesn't get activated.
  outa[hw#pin_SDA]~~                                    '
  dira[hw#pin_CLK0]~~                                   ' Set CLK0 pin to output for Phase 0 clock
  outa[hw#pin_CLK0]~~                                   ' Override the clock with a high signal for now

  ' Init video  
  screen_ptr := tv.Start(hw#pin_TV, font.GetPtrToFontTable) ' Start video output and get pointer to emulated screen RAM

  ' Init serial, keyboard and video viewport
  term.Start(hw#pin_RX, hw#pin_TX, hw#pin_KBDATA, hw#pin_KBCLK, BAUDRATE, screen_ptr, 40, 24, 40, 24, 0, 0)
  term.str(string(13,"L-STAR "))
  term.dec(RAM_SIZE)
  term.str(string(" BYTES HUB RAM, "))
  term.dec(@RomEnd-@RomFile)
  term.str(string(" BYTES ROM.",13,"REMEMBER TO USE CAPS-LOCK AND RESET.",13))

  ' Start the PIA emulator
  pia.Start($D010)
    
  ' Start the memory cog
  cognew(@MemCog, @@0)

  ' Start the clock at 1MHz
  ctra := %00100_000 << 23 + 1 << 9 + hw#pin_CLK0       ' Calculate frequency setting
  frqa := $333_0000                                     ' Set FRQA so PHSA[31]
  outa[hw#pin_CLK0]~                                    ' Remove override for the clock

  ' The following infinite loop emulates the terminal part of the machine.
  ' If a key has come in from the serial port or keyboard, it's made available to the PIA emulator;
  ' If the 6502 has written a character to the PIA, send it to the screen and the serial port.
  ' An '@' symbol is shown as the cursor (TODO: blink the cursor)
  repeat
    i := term.rxcheck
    if i <> -1
      pia.SendKey(i)
      
    i := pia.RcvDisp
    if i => 0
      if (i < 32) or (i > 126)
        term.str(string(32,8))
      term.tx(i)
      term.str(string(64,8))

DAT
                        org     0
MemCog
                        mov     DIRA, #0

                        ' Adjust the hub pointers. PAR should contain @@0.
                        '
                        ' The problem we're solving here is that the Spin
                        ' compiler writes module-relative values whenever the
                        ' @ operator is used in a DAT section, instead of
                        ' absolute hub locations. The Spin language has the
                        ' @@ operator to work around this (it converts a
                        ' module-relative pointer to an absolute pointer) so
                        ' @@0 represents the offset of the current module
                        ' which we can use to convert any pointers. It's much
                        ' more efficient to convert an entire pointer table
                        ' in Assembler than in Spin. Doing it in Assembler
                        ' also prevents problems such as accidentally doing
                        ' the conversion twice.
AdjustPtrTable                        
                        add     pointertable, PAR
                        add     AdjustPtrTable, d1
                        djnz    pointertable_len, #AdjustPtrTable

                        ' Convert hub address for start of ROM to offset
                        sub     pRomFile, romstart     
                             
WaitForPhi2
                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0                 
WaitForPhi1
                        ' Wait until clock goes low
                        waitpeq zero, mask_CLK0
' t=0
                        ' Take any previous data off the bus while we wait
                        ' for the address bus to settle (tADS < 40ns)
                        andn    DIRA, #hw#con_mask_DATA
' t=4
                        ' Get the inputs
                        mov     addr, INA
                        test    addr, mask_RW wz        ' Z=1 when 6502 is writing
                        shr     addr, #hw#pin_A0
                        and     addr, mask_FFFF         ' addr now contains address
' t=24                
                        ' Check if address is in ROM or RAM and calculate the
                        ' hub address.
                        ' We use a mathematical and logical trick here:
                        ' the ROM image is in the hub in front of the RAM
                        ' data, but in the 6502 the ROM is at the end of the
                        ' memory map. The pRomFile value is set to the offset
                        ' from the 6502 ROM start address to the hub start
                        ' address, and romstart is the calculated address of
                        ' the ROM in 6502 address space, given that the end
                        ' of the ROM is at the end of the address space.
                        ' If the address from the 6502 is in the ROM, it will
                        ' be between romstart and $FFFF (inclusive) and if it
                        ' is in RAM, it will be between 0 and ramsize
                        ' (exclusive). So we first test if the address is in
                        ' RAM, and if so, we add $1_0000 to the address so the
                        ' result is a value of $1_0000 to ($1_0000+ramsize)
                        ' (exclusive). That calculation maps the RAM behind
                        ' the ROM.
                        ' If the address is not in the RAM (and the addition
                        ' wasn't done) but it's within the ROM, add the
                        ' offset of the ROM hub address minus romstart
                        ' (the offset was already calculated by subtracting
                        ' the romstart value from pRomFile).
                        ' This yields an actual address in the hub that's
                        ' between @RomFile and @RomEnd (exclusive) for ROM
                        ' addresses, and between @RomEnd (which is also the
                        ' start of the RAM buffer) and @RomEnd+RAM_SIZE
                        ' (exclusive) for RAM addresses.
                        ' If the address is in ROM and the processor is
                        ' writing, ignore the request.    
                        cmp     ramsize, addr wc        ' C=0 if in RAM
        if_nc           add     addr, mask_10000        ' Convert RAM address to hub offset                          
        if_c_and_nz     cmp     addr, romstart wc       ' C=0 if in RAM, or reading from ROM
                        add     addr, pRomFile          ' Convert RAM or ROM address to hub address
        if_c            jmp     #WaitForPhi2            ' Writing to ROM or not accessing RAM or ROM, ignore
' t=44
        if_z            jmp     #Write                  ' Writing to RAM (the jump bridges the data setup time)
        
                        ' Get the byte from the hub
                        rdbyte  data, addr
' t=56..71                        
                        mov     OUTA, data
                        or      DIRA, #hw#con_mask_DATA
' t=64..79
                        jmp     #WaitForPhi1                        
' t=68..83

Write
' t=48
                        ' The 6502 is writing data. Phi2 has started by now
                        ' and we should be past the write data setup time
                        ' (tMDS < 40) so the data should be available on
                        ' the data bus by now.
                        ' Get the data (the bits above the data bus don't
                        ' matter)
                        mov     data, INA

                        ' Write the data to the correct address
                        ' We already know that it's in range
                        wrbyte  data, addr
' t=60..75
                        jmp     #WaitForPhi1
' t=64..79                        

                        ' NOTE: In both cases (read as well as write),
                        ' the worst-case scenario for the hub instruction
                        ' (RDBYTE/WRBYTE) makes the execution arrive a few
                        ' Propeller clockcycles late to the beginning
                        ' of the next 6502 clock cycle (t=81 or t=82).
                        ' However, it can be proven this is not a problem
                        ' because the bus states don't change significantly
                        ' when we probe the address bus and data bus a few
                        ' cycles late, and because the 6502 clock cycle
                        ' is an even multiple of 16 Propeller cycles, the
                        ' longer duration of the execution of one 6502 cycle
                        ' in the cog is guaranteed to execute the hub
                        ' instruction faster on the next iteration. In other
                        ' words, it catches up in the next 6502 clock cycle.                                                                                                   

'============================================================================
' Constants

zero                    long    0                       ' 0
d1                      long    (|<9)                   ' 1 in destination field
mask_CLK0               long    (|<hw#pin_CLK0)         ' Clock pin mask
mask_RW                 long    (|<hw#pin_RW)           ' R/!W pin mask in INA
mask_FFFF               long    $FFFF                   ' Mask for address after shifting
mask_10000              long    $10000                  ' Needed to calculate hub address

ramsize                 long    RAM_SIZE                ' Size of RAM in bytes
romstart                long    $1_0000 - (@RomEnd - @RomFile) ' Start address of ROM in 6502 space
                        

'============================================================================
' Data

pointertable
pRomFile                long    @RomFile
pointertable_len        long    (@pointertable_len - @pointertable) >> 2
addr                    long    0
data                    long    0

                        fit

DAT

RomFile
                        File    "65C02.rom.bin"         ' BASIC/Krusader/WOZ mon for 65C02
                        'File    "6502.rom.bin"          ' BASIC/Krusader/WOZ mon for 6502
RomEnd                        
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