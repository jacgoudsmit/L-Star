''***************************************************************************
''* Memory Cog for L-Star project
''* Copyright (C) 2014 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' This module allows the 65C02 to access hub memory of the Propeller as
'' regular ROM and/or RAM.
''
'' The module uses one cog to map a hub memory area that start with ROM and
'' ends with RAM, into the 65C02 address space. Either ROM or RAM area can
'' be zero bytes (in order to map only ROM or only RAM), and it's possible
'' and easy to make the mapping wrap around the end of 6502 address space,
'' so that the ROM maps to the high addresses and the RAM maps to low
'' addresses. That way, for many simple 6502 systems, only one cog is needed
'' to map all the necessary memory.
''
OBJ
  hw:   "Hardware"              ' Constants for hardware

VAR
  byte  MyCogId                 ' Cog ID + 1
  
PUB StartEx(RomStartParm, RomEndRamStartParm, RamEndParm, Offset6502Parm, ResetVectorParm) 
'' Start a memory cog to map hub memory into 65C02 address space
''
'' Parameters:
'' - RomStart: word
''   Hub address of the start of the ROM area to map into 65C02 address
''   space. In most cases, you would use a FILE command in a DAT section
''   to load a ROM image file to map into memory.
'' - RomEndRamStart: word
''   Hub address of the end of ROM and/or the start of RAM. If no ROM is
''   needed, set this pointer to the same address as RomStart
'' - RamEnd: word
''   Hub address of the end of RAM. If no RAM is needed, set this pointer
''   to the same address as RomEndRamStart.
'' - Offset6502: word
''   Start address in 65C02 address space where the memory should be mapped.
'' - ResetVector: word
''   If this parameter is nonzero, the cog simulates a reset by feeding BRK
''   instructions to the 65C02 at startup time until it picks up the IRQ/BRK
''   vector. The value of this parameter is fed to the 65C02 as reset vector,
''   after which normal operation commences.

  ' Stop first, in case we're already started 
  Stop

  pRomStart := RomStartParm
  pRomEndRamStart := RomEndRamStartParm
  pRamEnd := RamEndParm
  gOffset6502 := Offset6502Parm
  gResetVector := ResetVectorParm
  pCogId := @MyCogId
  
  result := cognew(@MemCog, @@0) => 0

  if result
    repeat until MyCogId ' The cog stores its own ID + 1

PUB Start(RomStartParm, RomEndRamStartParm, RamEndParm)
'' Start a memory cog to map ROM at the high end of 65C02 memory, and RAM at
'' the low end (wrapping around). The reset vector from the ROM area is used 
'' to fake a reset.

  return StartEx(RomStartParm, RomEndRamStartParm, RamEndParm, $1_0000 - (RomEndRamStartParm - RomStartParm), word[RomEndRamStartParm - 4])
     
PUB Stop
'' Stops the cog if it is running.

  if MyCogId
    cogstop(MyCogId~ - 1)


DAT
                        org     0
MemCog
                        ' Calculate the offset between a 65C02 address and
                        ' hub addresses
                        mov     addr, pRomStart
                        sub     addr, gOffset6502
                        mov     gOffset6502, addr                        
                        
                        ' Let caller know we're running by storing cogid + 1
                        cogid   data
                        add     data, #1
                        wrbyte  data, pCogId

                        ' Skip the fake reset if no reset vector was given
                        cmp     gResetVector, zero wz
        if_z            jmp     #WaitForPhi2
                             
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

FakeResetVector1
                        mov     OUTA, gResetVector
                        or      DIRA, #hw#con_mask_DATA
                        jmp     #FakeResetWaitForPhi2

FakeResetVector2
                        mov     data, gResetVector
                        shr     data, #8
                        mov     OUTA, data
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
                        add     addr, gOffset6502
                        and     addr, mask_FFFF
' t=20
                        ' Check if the address is in ROM or RAM
                        cmp     pRamEnd, addr wc        ' C=0 if below end of RAM
        if_nc           cmp     addr, pRomStart wc      ' C=0 if in ROM or RAM

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

addr                    long    0
data                    long    0

'============================================================================
' Parameters

pCogId                  long    0                       ' Hub pointer where cog ID + 1 is stored
pRomStart               long    0                       ' Hub pointer to start of ROM
pRomEndRamStart         long    0                       ' Hub pointer to end of ROM, start of RAM
pRamEnd                 long    0                       ' Hub pointer to end of RAM 
gResetVector            long    0                       ' Reset vector used for fake reset; 0=skip
gOffset6502             long    0                       ' 6502 address for start of ROM

                        fit

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