This project emulates an Apple 1 via the serial port.
- It emulates 8KB ROM and 6K RAM. The ROM is the same memory image
  file as in the Apple 1 spin project but the RAM had to be reduced
  because the LMM C runtime takes up more space
- The PIA in the Apple 1 is emulated by a cog running a thread function.
  It uses the volatile members in a struct in the hub to communicate
- The main program checks for incoming keys and outgoing characters and
  forwards them from/to the serial port as fast as possible. It does
  this once per half clock pulse which slows things down quite a bit,
  but the system still runs fast enough to be usable.

No screen or keyboard are needed.
Jumpers settings are irrelevant.
No SRAM is needed.

Usage:

1. In SimpleIDE, load the demo3.side project.
2. Connect the Prop Plug to the L-Star and to the PC. In SimpleIDE, the
   COM port should be detected automatically (if not, refer to the 
   SimpleIDE documentation).
3. Use the Run With Terminal button or menu option (under "Program"),
   or hit F8 on your keyboard.
4. In the terminal, you should see "Hello L-Star!". If not, make sure
   it's set to 115200 bps.
5. After the Hello message, what you type into the terminal is received
   by the 65C02 via the emulated Apple 1 hardware. The 65C02 can also
   send text to the terminal via the same emulated hardware.
6. The processor may hit a breakpoint which makes it land in the
   Krusader debugger. To go to the Woz monitor (the original Apple 1
   user interface), push the Reset6502 button. This will show a block
   character followed by a backslash.
7. You can start the Woz BASIC interpreter by entering E000R. You
   can start Krusader by entering F000R. To go back to Woz mon, hit
   the reset button again.
   