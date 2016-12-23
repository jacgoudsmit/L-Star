/////////////////////////////////////////////////////////////////////////////
// Demo/Tutorial project 1 for L-Star project
// Copyright (C) 2016 Jac Goudsmit
//
// TERMS OF USE: MIT License. See bottom of file.                                                            
/////////////////////////////////////////////////////////////////////////////


// This project demonstrates how the Propeller bitbangs the 6502.
// No screen or keyboard are needed.
// Jumpers settings are irrelevant.
// No SRAM is needed.
//
// Usage:
// 1. In SimpleIDE, load the Demo1.side project.
// 2. Connect the Prop Plug to the L-Star and to the PC. In SimpleIDE, the
//    COM port should be detected automatically (if not, refer to the 
//    SimpleIDE documentation).
// 3. Use the Run With Terminal button or menu option (under "Program"),
//    or hit F8 on your keyboard.
// 4. In the terminal, you should see "Hello L-Star!". If not, make sure
//    it's set to 115200 bps.
// 5. Hit the C button on your keyboard to toggle the clock of the 65C02.
//    In other words: each button press of the C button is half of a clock
//    cycle.
// 6. Every time the clock goes from high to low, you will see the address
//    change. Except if you just powered up your board; in that case the
//    65C02 is in a blocked state. Resetting the 65C02 will fix this;
//    see below.
// 7. When the clock is high and the 6502 is in write mode, the data bus
//    value is valid. It's executing random code because nothing else puts
//    any signals on the databus in this project.
// 8. Push and hold the Reset6502 button and generate 2 clock cycles (hit
//    the C button on your keyboard 4 times to make the clock go
//    Low-High-Low-High). Then release the Reset6502 button again.
// 9. Keep hitting the C button and you will see the 65C02 execute the
//    reset cycle:
//    - First you'll see two clock cycles with random addresses.
//      This is just the internal electronics flushing things out before
//      starting the reset.
//    - Then you'll see three clock cycles where the 65C02 reads decreasing
//      addresses of the stack (addresses between $100 and $1FF). The 65C02
//      handles the reset like an interrupt, but the read/write line is
//      forced High (read mode) so that the stack doesn't get overwritten
//      during the reset.
//    - The 65C02 then reads the reset vector at $FFFC and $FFFD, and
//      jumps to the address that it reads off the bus and starts executing
//      code there.


/////////////////////////////////////////////////////////////////////////////
// INCLUDES
/////////////////////////////////////////////////////////////////////////////


#include "fdserial.h"
#include "simpletools.h"


/////////////////////////////////////////////////////////////////////////////
// MACROS
/////////////////////////////////////////////////////////////////////////////


// Generate a Bit Mask based on a number of bits and a shift-value
// Example: BM(3, 1) generates 0b1110
#define BM(n, s) (((1 << (n)) - 1) << (s))

// Generate a bit pattern for a single bit based on shift-value
// Example: BP(4) generates 0b10000
#define BP(s) (1 << (s))

// Decode a value from a bit pattern based on number of bits and shift-value
// Example: BD(0b1011, 3, 1) returns 5 (0b101)
#define BD(v, n, s) (((v) & BM((n), (s))) >> (s))

// Encode a value as a bit pattern based on number of bits and shift-value
// Example: BE(5, 3, 2) returns 0b10100. 
#define BE(v, n, s) (((v) << (s)) & (BM((n), (s))))

// Insert a value as a bit pattern based on number of bits and shift-value
// Example: BI(0b1100111, 0b100, 3, 2) returns 0b1110011.
#define BI(i, v, n, s) (((i) & ~BM((n), (s))) | BE((v), (n), (s)))

// Decode the data bus
// Example: dprint(term, "%2X" get_DATA(INA))
#define get_DATA(x) BD(x, 8, pin_D0)

// Set the data bus
// Example: OUTA = set_DATA(OUTA, $A7)
#define set_DATA(x, v) BI(x, v, 8, pin_D0)

// Decode the address bus
// Example: dprint(term, "%X", get_ADDR(INA))
#define get_ADDR(x) BD(x, 16, pin_A0)


/////////////////////////////////////////////////////////////////////////////
// TYPES
/////////////////////////////////////////////////////////////////////////////


// Mnemonics for all pins
typedef enum
{
  // Data bus
  pin_D0,
  pin_D1,
  pin_D2,
  pin_D3,
  pin_D4,
  pin_D5,
  pin_D6,
  pin_D7,
  
  // Address bus
  pin_A0,
  pin_A1,
  pin_A2,
  pin_A3,
  pin_A4,
  pin_A5,
  pin_A6,
  pin_A7,
  pin_A8,
  pin_A9,
  pin_A10,
  pin_A11,
  pin_A12,
  pin_A13,
  pin_A14,
  pin_A15,
  
  // Read/Not Write
  pin_RW,
  
  // I/O pins
  pin_P25,
  pin_P26,
  pin_P27,
  
  // I2C bus
  pin_CLK0,
  pin_SDA,
  
  // Serial port
  pin_TX,
  pin_RX
  
} pin;


/////////////////////////////////////////////////////////////////////////////
// DATA
/////////////////////////////////////////////////////////////////////////////


// Pointer to use for terminal calls.
terminal *term;

  
/////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
/////////////////////////////////////////////////////////////////////////////


//---------------------------------------------------------------------------
// Print the pins
void print_ina(void)
{
  unsigned u = INA;
  
  // Show the PHI2 output to the 6502, the three I/O lines P27/P26/P25,
  // the R/!W line, the address bus and the data bus.
  dprint(term, "%c %c%c%c %c %04x %02x\n", 
    (BD(u, 1, pin_CLK0) ? 'H' : 'L'),  // CLK
    (BD(u, 1, pin_P27)  ? '1' : '0'),  // P27 (e.g. !RAMEN)
    (BD(u, 1, pin_P26)  ? '1' : '0'),  // P26
    (BD(u, 1, pin_P25)  ? '1' : '0'),  // P25
    (BD(u, 1, pin_RW)   ? 'R' : 'W'),  // !R/W
    get_ADDR(u),                       // Address bus
    get_DATA(u));                      // Data bus
    
  // Not shown are
  // - P31/P30 (serial port, so changes all the time)
  // - P29 (EEPROM data line, always high)
}


//---------------------------------------------------------------------------
// Main function
int main()
{
  // Close the default same-cog terminal so it doesn't interfere,
  // and start a full-duplex terminal on another cog.
  simpleterm_close();
  term = fdserial_open(31, 30, 0, 115200);

  // The clock of the 65C02 is shared with the SCL clock line of the I2C
  // bus that's connected to the EEPROM that holds the Propeller firmware.
  // We need to keep SDA High to keep the EEPROM from activating, and we
  // need to set the direction for the SCL / CLK0 to OUTPUT so we can
  // clock the 6502. There are two pull-up resistors that pull the lines
  // High until we do this, so if we make sure the output is set to High
  // before we set the set the direction to output, nothing bad will
  // happen.
  OUTA |= (BP(pin_SDA) | BP(pin_CLK0));
  DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
  
  // Initialization done
  dprint(term, "Hello L-Star!\n");

  for(;;)
  {
    int c = fdserial_rxTime(term, 500);
    
    switch (c)
    {
    case 'c':
    case 'C':
      // Toggle the clock
      OUTA ^= BP(pin_CLK0);
      break;
      
    default:
      continue;
    }
    
    // Print the state of the pins
    print_ina();
  }  
}



//**************************************************************************/
// MIT License
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
// OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
// THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//**************************************************************************/
