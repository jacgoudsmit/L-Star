/////////////////////////////////////////////////////////////////////////////
// Demo/Tutorial project 3 for L-Star project
// Copyright (C) 2016 Jac Goudsmit
//
// TERMS OF USE: MIT License. See bottom of file.                                                            
/////////////////////////////////////////////////////////////////////////////

/*
 * This project emulates an Apple 1 (really a Briel Computers Replica 1)
 * via the serial port.
 */

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
#define set_DATA(x, v) do { x = BI(x, v, 8, pin_D0); } while (0)

// Decode the address bus
// Example: dprint(term, "%X", get_ADDR(INA))
#define get_ADDR(x) BD(x, 16, pin_A0)

// Get the R/!W pin
// Example: dprint(term, "%c", get_RW(INA) ? 'R' : 'W');
#define get_RW(x) BD(x, 1, pin_RW)


// Size of the ROM in bytes. Unfortunately it's not possible to determine
// this automatically; this number needs to be the same as the ROM image
// that's loaded through the Spin module.
#define ROMSIZE (8192)


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
  
  // Uncommitted I/O pins
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


// Initialization data for memory cog
typedef struct
{
  uint8_t          *romstart;           // Location of first ROM byte
  uint8_t          *romend_ramstart;    // Location of first RAM byte
  uint8_t          *ramend;             // Location of first byte after RAM
  
  uint16_t          base6502;           // Base address in 6502 space
  
} memory_init_t;


// Data interchange between PIA cog and other cogs
typedef struct
{
  uint16_t          base6502;           // Base address in 6502 space
                                        //   (low 2 bits must be 0)
  volatile char     display;            // Output from PIA, msb=1 when new
  volatile char     keyboard;           // Input to PIA, msb=1 when new
  
} pia_io_t;

  
/////////////////////////////////////////////////////////////////////////////
// DATA
/////////////////////////////////////////////////////////////////////////////


// Pointer to use for terminal calls.
terminal *term;

// External references to the Spin module where the binary ROM image is
// loaded and RAM space is reserved.
extern uint8_t binary_romram_dat_start[];
extern uint8_t binary_romram_dat_end[];



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
// Patch mapped memory
void memorypatch(memory_init_t *pinit, uint16_t addr, uint8_t data)
{
  pinit->romstart[(addr - pinit->base6502) & 0xFFFF] = data;
}

  
//---------------------------------------------------------------------------
// Memory cog
void memorycog(void *arg)
{
  memory_init_t *p = (memory_init_t *)arg;

  uint8_t *hubmem = p->romstart;
  uint16_t romsize = p->romend_ramstart - p->romstart;
  uint16_t ramsize = p->ramend - p->romend_ramstart;
  uint16_t base6502 = p->base6502;
  
  for(;;)
  {
    // Wait until the clock goes low
    waitpeq(0, BP(pin_CLK0));
    
    // If we put anything on the data bus in the previous cycle, take it off.
    set_DATA(DIRA, 0);
    
    // Get the address and check if it's in range
    unsigned addr = get_ADDR(INA);
    
    // Calculate offset in array
    addr = (addr - base6502) & 0xFFFF;
    
    // Wait until the clock goes high
    waitpne(0, BP(pin_CLK0));

    // Check if the address is in range    
    if (addr < romsize + ramsize)
    {
      // Check for read or write mode
      if (get_RW(INA))
      {
        // The 65C02 is reading, put data from the array on the data bus
        OUTA = (unsigned)hubmem[addr];
        set_DATA(DIRA, 0xFF);
      }
      else
      {
        // The 6502 is writing. Make sure we don't overwrite the ROM
        if (addr >= romsize)
        {
          hubmem[addr] = (uint8_t)INA;
        }
      }
    }                        
  }    
}


//---------------------------------------------------------------------------
// Apple 1 PIA emulator
void a1piacog(void *arg)
{
  pia_io_t *p = (pia_io_t*)arg;
  
  // Keep the base address in a local variable.
  // Make sure the lowest 2 bits are zero.
  unsigned base6502 = ((unsigned)(p->base6502)) & 0xFFFC;
  
  for(;;)
  {
    // Wait until the clock goes low
    waitpeq(0, BP(pin_CLK0));
    
    // If we put anything on the data bus in the previous cycle, take it off.
    set_DATA(DIRA, 0);
    
    // Get the address
    unsigned addr = get_ADDR(INA);
    
    // Check if the address is in range
    // We do this by XOR-ing the actual address with the base address
    // If in range, this results in a value of 0 to 3.
    switch(addr ^ base6502)
    {
    case 0:
      // Read key code (write operations ignored)
      if (get_RW(INA))
      {
        unsigned u = p->keyboard;

        // The msb of the key code is always 1
        OUTA = u | 0x80;
        set_DATA(DIRA, 0xFF);
        
        // Reset the key flag
        p->keyboard = u & 0x7F;
      }            
      
      // Wait for the clock to go high, if it hasn't done so yet
      waitpne(0, BP(pin_CLK0));
      break;
      
    case 1:
      // Read the key flag (write operations ignored)
      if (get_RW(INA))
      {
        // Put a byte on the data bus
        // Bit 7 is the only significant one and
        // indicates whether a new key is available
        OUTA = p->keyboard;
        set_DATA(DIRA, 0xFF);
      }        

      // Wait for the clock to go high, if it hasn't done so yet
      waitpne(0, BP(pin_CLK0));
      break;
      
    case 2:
      // Read or write the display register
      if (get_RW(INA))
      {
        // Reading back the last byte that was sent to the
        // display.
        OUTA = p->display;
        set_DATA(DIRA, 0xFF);
      }
      else
      {
        // The 65C02 is writing a byte to the display
        // Wait until the clock is high first, so we
        // can be sure the 65C02 is putting something on the data bus
        waitpne(0, BP(pin_CLK0));

        // Store the outgoing display byte.
        // Bit 7 should always be 1 to indicate something new was
        // stored.
        p->display = get_DATA(INA) | 0x80;
      }                
      break;
      
    case 3:
      // Register 3 is the control and status register.
      // We can ignore that and fall through to the default case.
      
    default:
      // Wait until the clock goes high
      waitpne(0, BP(pin_CLK0));
    }      
  }    
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
  
  // Start the memory cog
  uint8_t memorystack[sizeof(_thread_state_t) + 12]; // At least 12 extra bytes needed or cogstart fails
  memory_init_t meminit = { binary_romram_dat_start, binary_romram_dat_start + ROMSIZE, binary_romram_dat_end, 0x10000 - ROMSIZE };
  (void)cogstart(memorycog, &meminit, memorystack, sizeof(memorystack));

  // Start the Apple 1 PIA cog
  uint8_t piastack[sizeof(_thread_state_t) + 12]; // At least 12 extra bytes needed or cogstart fails
  pia_io_t piadata = { 0xD010, '\0', '\0' };
  (void)cogstart(a1piacog, &piadata, piastack, sizeof(piastack));

  // Patch the Krusader ROM
  // Without this, it thinks the system has 32K.
  // The patch moves the symbol table to $1400 (end of RAM is $1800)
  memorypatch(&meminit, 0xF009, 0x14);
  
  // Initialization done
  dprint(term, "Hello L-Star!\n");

  for(;;)
  {
    if ((piadata.keyboard & 0x80) == 0)
    {
      int c = fdserial_rxCheck(term);
      
      if (c != -1)
      {
        piadata.keyboard = (unsigned)(c | 0x80);
      }
    }
    
    if ((piadata.display & 0x80) != 0)
    {
      writeChar(term, piadata.display & 0x7F);
      piadata.display &= 0x7F;
    }

    // Toggle the clock
    toggle(pin_CLK0);
    
    // Dump the bus
    //print_ina();
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
