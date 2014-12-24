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
  hw:   "Hardware"              ' Constants for hardware
  term: "SerKbd1TV"             ' Serial/Keyboard/TV terminal
  pia:  "A1PIA"                 ' PIA hardware emulator  

PUB main | i, screen_ptr

  ' Initialize the clock and SDA pins as output, and set them both high for now,
  ' so that the 6502 access cogs can ready themselves by waiting for CLK0 to go low.
  outa[hw#pin_SDA]~~                                    '
  dira[hw#pin_SDA]~~                                    ' The SDA pin must remain high so the EEPROM doesn't get activated.
  outa[hw#pin_CLK0]~~                                   ' Override the clock with a high signal for now
  dira[hw#pin_CLK0]~~                                   ' Set CLK0 pin to output for Phase 0 clock

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

                        ' Fake reset
                        '
                        ' For the first few cycles that we control the 65C02,
                        ' we force it to read bytes with value 0. Write
                        ' cycles are ignored so the simulated RAM in the hub
                        ' is not disturbed.
                        '
                        ' The 65C02 interprets the 0 value as a BRK
                        ' instruction, and retrieves the BRK/IRQ vector from
                        ' locations $FFFE and $FFFF, When it does this, we
                        ' pass it the bytes from the reset vector ($FFFC and
                        ' FFFD) in the ROM area, and then continue in normal
                        ' operation mode.
                        ' 
                        ' There is a small chance that this won't work, for
                        ' example if the 65C02 was already reading from
                        ' locations FFFE or FFFF. Also if an older (non-WDC)
                        ' 6502 is used, it's possible that it might be stuck
                        ' in an illegal instruction that it can't get out
                        ' of. Also, the WDC 65C02 has the WAI and STP
                        ' instructions that make it go into a state where it
                        ' doesn't execute any instructions at all.
                        ' In those cases, the user will really have to
                        ' push the reset button after resetting the
                        ' Propeller. Oh well.
                        '
                        ' The code to accomplish the fake reset is a partial
                        ' duplicate of the main loop. Unfortunately it's not
                        ' possible to implement the overlap in functionality
                        ' by using a subroutine (there aren't enough unused
                        ' cycles to insert extra JMPRET instructions). Using
                        ' self-modifying code might be possible but it would
                        ' make the code more difficult to read, and it's not
                        ' really necessary because there's plenty of space in
                        ' the cog to put the same code twice. Nevertheless,
                        ' I apologize fot the copy-and-paste.   
FakeResetWaitForPhi2
                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0                 
FakeResetWaitForPhi1
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
                        
        if_z            jmp     #FakeResetWaitForPhi2   ' Writing, ignore this cycle

                        cmp     addr, mask_FFFE wz
        if_z            jmp     #FakeResetVector1

                        cmp     addr, mask_FFFF wz
        if_z            jmp     #FakeResetVector2

                        ' Feed a zero        
                        mov     OUTA, #0
                        or      DIRA, #hw#con_mask_DATA
                        jmp     #FakeResetWaitForPhi2

FakeResetVector1        rdbyte  OUTA, pFFFC
                        or      DIRA, #hw#con_mask_DATA
                        jmp     #FakeResetWaitForPhi2

FakeResetVector2        rdbyte  OUTA, pFFFD
                        or      DIRA, #hw#con_mask_DATA
                        ' Fall through to the main loop...

WaitForPhi2
                        ' Wait until clock goes high
                        waitpne zero, mask_CLK0

                        ' MAIN LOOP
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
                        shr     addr, #hw#pin_A0        ' Shift address bus to bottom bits
' t=12
                        ' Calculate hub address
                        ' We do this by adding the RAM start address and then
                        ' masking the address with $FFFF (in that order).
                        ' That way, ROM addresses will "wrap around" and
                        ' their hub addresses end up just below the RAM.
                        '
                        ' For example, if the 6502 requests address $FFFF,
                        ' the "addr" variable contains $????FFFF now (the top
                        ' 16 bits are filled with unknown bits that don't
                        ' matter). We add the hub location for the start of
                        ' RAM, let's say $0123 (that's not the real address!)
                        ' This results in a value that ends in $0122; which
                        ' is one byte ahead of the RAM start location in the
                        ' hub. All we need to do is mask the bottom bits.
                        ' (This trick is only possible because we know that
                        ' hub addresses are 16 bits too, by the way).
                        add     addr, pRomEndRamStart
                        and     addr, mask_FFFF
' t=20
                        ' Check if the address is in ROM or RAM
                        cmp     pRamEnd, addr wc        ' C=0 if below end of RAM
        if_nc           cmp     addr, pRomFile wc       ' C=0 if in ROM or RAM

                        ' Don't do anything if the address is out of range
        if_c            jmp     #WaitForPhi2        
         
' t=32
        if_z            jmp     #Write                  ' Writing to RAM
' t=36        
                        ' Get the byte from the hub
                        rdbyte  data, addr
' t=44..59
                        ' By now, CLK0 is high; Phi2 has started.
                        ' Put the data on the data bus                        
                        mov     OUTA, data
                        or      DIRA, #hw#con_mask_DATA
' t=52..67
                        jmp     #WaitForPhi1                        
' t=56..71

Write
' t=36                  
                        ' The 6502 is writing data, but we have to wait
                        ' until it sets up the data on the data bus which
                        ' doesn't happen until a little after the clock
                        ' goes high.
                        ' Wait for it, in case the clock frequency is set
                        ' to a low value for testing.
                        waitpne zero, mask_CLK0
' t=42
                        ' Wait for the data setup time (tMDS < 40ns)
                        ' Meanwhile, make sure we're not trying to write to ROM
                        cmp     addr, pRomEndRamStart wc ' C=0 if in RAM                          
' t=46
                        ' Get the data (the bits above the data bus don't
                        ' matter)
        if_nc           mov     data, INA
' t=50
                        ' Write the data to the correct address
                        ' We already know that it's in range
        if_nc           wrbyte  data, addr
' t=58..73
                        jmp     #WaitForPhi1
' t=62..77
                        ' NOTE: In the case where the 6502 writes to RAM,
                        ' the worst-case scenario for the hub instruction
                        ' (RDBYTE/WRBYTE) makes the execution arrive a few
                        ' Propeller clock cycles late to the beginning
                        ' of the next 6502 clock cycle: WaitPXX instructions
                        ' take at least 6 Propeller cycles and in the worst
                        ' case scenario, the Wait instruction is started
                        ' at t=77 i.e. it will finish at t=3 of the next
                        ' 6502 cycle instead of t=0.
                        '
                        ' However, this is not a problem because the 6502
                        ' bus states don't change significantly if we probe
                        ' them a few Propeller cycles late.
                        '
                        ' Also, because the 6502 cycle (1MHz = 80 Propeller
                        ' cycles) is an even multiple of 16 (80=16*5), the
                        ' wrbyte instruction on the next write cycle will
                        ' be started a little later, which makes the waiting
                        ' time shorter. In other words: the problem will
                        ' solve itself in the next cycle, instead of
                        ' escalating.

'============================================================================
' Constants

zero                    long    0                       ' 0
d1                      long    (|<9)                   ' 1 in destination field
mask_CLK0               long    (|<hw#pin_CLK0)         ' Clock pin mask
mask_RW                 long    (|<hw#pin_RW)           ' R/!W pin mask in INA
mask_FFFE               long    $FFFE                   ' Low byte of BRK vector
mask_FFFF               long    $FFFF                   ' Mask for address after shifting; high byte of BRK vector

'============================================================================
' Data

pointertable
pRomFile                long    @RomFile
pRomEndRamStart         long    @RomEndRamStart
pRamEnd                 long    @RamEnd
pFFFC                   long    @RomEndRamStart - 4
pFFFD                   long    @RomEndRamStart - 3 
pointertable_len        long    (@pointertable_len - @pointertable) >> 2

addr                    long    0
data                    long    0

                        fit

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