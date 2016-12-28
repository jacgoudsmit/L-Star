This project demonstrates how the Propeller bitbangs the 6502.
In addition to the previous project, this also demonstrates how to
run a cog that emulates ROM and RAM.

No screen or keyboard are needed.
Jumpers settings are irrelevant.
No SRAM is needed.

Usage:

1. In SimpleIDE, load the Demo1.side project.
2. Connect the Prop Plug to the L-Star and to the PC. In SimpleIDE, the
   COM port should be detected automatically (if not, refer to the 
   SimpleIDE documentation).
3. Use the Run With Terminal button or menu option (under "Program"),
   or hit F8 on your keyboard.
4. In the terminal, you should see "Hello L-Star!". If not, make sure
   it's set to 115200 bps.
5. Hit the C button on your keyboard to toggle the clock of the 65C02.
   In other words: each button press of the C button is half of a clock
   cycle.
6. Every time the clock goes from high to low, you will see the address
   change. Except if you just powered up your board; in that case the
   65C02 is in a blocked state. Resetting the 65C02 will fix this;
   see below.
7. When the clock is high and the 6502 is in write mode, the data bus
   value is put on the bus by the 65C02. In read mode, the 65C02 reads
   the value from the data bus when the clock goes from high to low.
   In this demo, a separate cog of the Propeller is used to represent
   an array of bytes in the Propeller's hub to the 65C02 as ROM and RAM.
   The ROM is mapped in the $FFF0-$FFFF area of 65C02 address space, the
   RAM is mapped to $0000-$02FF. The program in the ROM does nothing
   other than repeatedly increment the byte at location $200.
8. Push and hold the Reset6502 button and generate 2 clock cycles (hit
   the C button on your keyboard 4 times to make the clock go
   Low-High-Low-High). Then release the Reset6502 button again.
9. Keep hitting the C button and you will see the 65C02 execute the
   reset cycle:
   - First you'll see two clock cycles with random addresses.
     This is just the internal electronics flushing things out before
     starting the reset.
   - Then you'll see three clock cycles where the 65C02 reads decreasing
     addresses of the stack (addresses between $100 and $1FF). The 65C02
     handles the reset like an interrupt, but the read/write line is
     forced High (read mode) so that the stack doesn't get overwritten
     during the reset.
   - The 65C02 then reads the reset vector at $FFFC and $FFFD, and
     jumps to the address that it reads off the bus and starts executing
     code there.
