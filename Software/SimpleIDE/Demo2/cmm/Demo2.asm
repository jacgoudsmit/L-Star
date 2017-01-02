 GNU assembler version 2.21 (propeller-elf)
	 using BFD version (propellergcc_v1_0_0_2408) 2.21.
 options passed	: -lmm -cmm -ahdlnsg=cmm/Demo2.asm 
 input file    	: C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s
 output file   	: cmm/Demo2.o
 target        	: propeller-parallax-elf
 time stamp    	: 

   1              		.text
   2              	.Ltext0
   3              		.data
   4              		.balign	4
   5              	.LC0
   6 0000 25632025 		.ascii "%c %c%c%c %c %04x %02x\12\0"
   6      63256325 
   6      63202563 
   6      20253034 
   6      78202530 
   7              		.text
   8              		.global	_print_ina
   9              	_print_ina
  10              	.LFB1
  11              		.file 1 "Demo2.c"
   1:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
   2:Demo2.c       **** // Demo/Tutorial project 2 for L-Star project
   3:Demo2.c       **** // Copyright (C) 2016 Jac Goudsmit
   4:Demo2.c       **** //
   5:Demo2.c       **** // TERMS OF USE: MIT License. See bottom of file.                                                  
   6:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
   7:Demo2.c       **** 
   8:Demo2.c       **** 
   9:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  10:Demo2.c       **** // INCLUDES
  11:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  12:Demo2.c       **** 
  13:Demo2.c       **** 
  14:Demo2.c       **** #include "fdserial.h"
  15:Demo2.c       **** #include "simpletools.h"
  16:Demo2.c       **** 
  17:Demo2.c       **** 
  18:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  19:Demo2.c       **** // MACROS
  20:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  21:Demo2.c       **** 
  22:Demo2.c       **** 
  23:Demo2.c       **** // Generate a Bit Mask based on a number of bits and a shift-value
  24:Demo2.c       **** // Example: BM(3, 1) generates 0b1110
  25:Demo2.c       **** #define BM(n, s) (((1 << (n)) - 1) << (s))
  26:Demo2.c       **** 
  27:Demo2.c       **** // Generate a bit pattern for a single bit based on shift-value
  28:Demo2.c       **** // Example: BP(4) generates 0b10000
  29:Demo2.c       **** #define BP(s) (1 << (s))
  30:Demo2.c       **** 
  31:Demo2.c       **** // Decode a value from a bit pattern based on number of bits and shift-value
  32:Demo2.c       **** // Example: BD(0b1011, 3, 1) returns 5 (0b101)
  33:Demo2.c       **** #define BD(v, n, s) (((v) & BM((n), (s))) >> (s))
  34:Demo2.c       **** 
  35:Demo2.c       **** // Encode a value as a bit pattern based on number of bits and shift-value
  36:Demo2.c       **** // Example: BE(5, 3, 2) returns 0b10100. 
  37:Demo2.c       **** #define BE(v, n, s) (((v) << (s)) & (BM((n), (s))))
  38:Demo2.c       **** 
  39:Demo2.c       **** // Insert a value as a bit pattern based on number of bits and shift-value
  40:Demo2.c       **** // Example: BI(0b1100111, 0b100, 3, 2) returns 0b1110011.
  41:Demo2.c       **** #define BI(i, v, n, s) (((i) & ~BM((n), (s))) | BE((v), (n), (s)))
  42:Demo2.c       **** 
  43:Demo2.c       **** // Decode the data bus
  44:Demo2.c       **** // Example: dprint(term, "%2X" get_DATA(INA))
  45:Demo2.c       **** #define get_DATA(x) BD(x, 8, pin_D0)
  46:Demo2.c       **** 
  47:Demo2.c       **** // Set the data bus
  48:Demo2.c       **** // Example: OUTA = set_DATA(OUTA, $A7)
  49:Demo2.c       **** #define set_DATA(x, v) BI(x, v, 8, pin_D0)
  50:Demo2.c       **** 
  51:Demo2.c       **** // Decode the address bus
  52:Demo2.c       **** // Example: dprint(term, "%X", get_ADDR(INA))
  53:Demo2.c       **** #define get_ADDR(x) BD(x, 16, pin_A0)
  54:Demo2.c       **** 
  55:Demo2.c       **** 
  56:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  57:Demo2.c       **** // TYPES
  58:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  59:Demo2.c       **** 
  60:Demo2.c       **** 
  61:Demo2.c       **** // Mnemonics for all pins
  62:Demo2.c       **** typedef enum
  63:Demo2.c       **** {
  64:Demo2.c       ****   // Data bus
  65:Demo2.c       ****   pin_D0,
  66:Demo2.c       ****   pin_D1,
  67:Demo2.c       ****   pin_D2,
  68:Demo2.c       ****   pin_D3,
  69:Demo2.c       ****   pin_D4,
  70:Demo2.c       ****   pin_D5,
  71:Demo2.c       ****   pin_D6,
  72:Demo2.c       ****   pin_D7,
  73:Demo2.c       ****   
  74:Demo2.c       ****   // Address bus
  75:Demo2.c       ****   pin_A0,
  76:Demo2.c       ****   pin_A1,
  77:Demo2.c       ****   pin_A2,
  78:Demo2.c       ****   pin_A3,
  79:Demo2.c       ****   pin_A4,
  80:Demo2.c       ****   pin_A5,
  81:Demo2.c       ****   pin_A6,
  82:Demo2.c       ****   pin_A7,
  83:Demo2.c       ****   pin_A8,
  84:Demo2.c       ****   pin_A9,
  85:Demo2.c       ****   pin_A10,
  86:Demo2.c       ****   pin_A11,
  87:Demo2.c       ****   pin_A12,
  88:Demo2.c       ****   pin_A13,
  89:Demo2.c       ****   pin_A14,
  90:Demo2.c       ****   pin_A15,
  91:Demo2.c       ****   
  92:Demo2.c       ****   // Read/Not Write
  93:Demo2.c       ****   pin_RW,
  94:Demo2.c       ****   
  95:Demo2.c       ****   // Uncommitted I/O pins
  96:Demo2.c       ****   pin_P25,
  97:Demo2.c       ****   pin_P26,
  98:Demo2.c       ****   pin_P27,
  99:Demo2.c       ****   
 100:Demo2.c       ****   // I2C bus
 101:Demo2.c       ****   pin_CLK0,
 102:Demo2.c       ****   pin_SDA,
 103:Demo2.c       ****   
 104:Demo2.c       ****   // Serial port
 105:Demo2.c       ****   pin_TX,
 106:Demo2.c       ****   pin_RX
 107:Demo2.c       ****   
 108:Demo2.c       **** } pin;
 109:Demo2.c       **** 
 110:Demo2.c       **** 
 111:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 112:Demo2.c       **** // DATA
 113:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 114:Demo2.c       **** 
 115:Demo2.c       **** 
 116:Demo2.c       **** // Pointer to use for terminal calls.
 117:Demo2.c       **** terminal *term;
 118:Demo2.c       **** 
 119:Demo2.c       ****   
 120:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 121:Demo2.c       **** // FUNCTIONS
 122:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 123:Demo2.c       **** 
 124:Demo2.c       **** 
 125:Demo2.c       **** //---------------------------------------------------------------------------
 126:Demo2.c       **** // Print the pins
 127:Demo2.c       **** void print_ina(void)
 128:Demo2.c       **** {
  12              		.loc 1 128 0
  13 0000 031F     		lpushm	#16+15
  14              	.LCFI0
  15 0002 0CE0     		sub	sp, #32
  16              	.LCFI1
 129:Demo2.c       ****   unsigned u = INA;
  17              		.loc 1 129 0
  18 0004 F2000EA0 		mov	r7, INA
  19              	.LVL0
 130:Demo2.c       ****   
 131:Demo2.c       ****   // Show the PHI2 output to the 6502, the three I/O lines P27/P26/P25,
 132:Demo2.c       ****   // the R/!W line, the address bus and the data bus.
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  20              		.loc 1 133 0
  21 0008 660000   		mviw	r6,#_term
  22 000b 106D     		rdlong	r0, r6
 134:Demo2.c       ****     (BD(u, 1, pin_CLK0) ? 'H' : 'L'),  // CLK
  23              		.loc 1 134 0
  24 000d 0A67     		mov	r6, r7
  25 000f 361CA0   		shr	r6, #28
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  26              		.loc 1 133 0
  27 0012 F9010C60 		test	r6,#0x1 wz
 135:Demo2.c       ****     (BD(u, 1, pin_P27)  ? '1' : '0'),  // P27 (e.g. !RAMEN)
  28              		.loc 1 135 0
  29 0016 0A67     		mov	r6, r7
  30 0018 361BA0   		shr	r6, #27
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  31              		.loc 1 133 0
  32 001b 85A14C   		IF_E  mov	r1,#76
  33 001e 8AA148   		IF_NE mov	r1,#72
  34 0021 F9010C60 		test	r6,#0x1 wz
 136:Demo2.c       ****     (BD(u, 1, pin_P26)  ? '1' : '0'),  // P26
  35              		.loc 1 136 0
  36 0025 0A67     		mov	r6, r7
  37 0027 361AA0   		shr	r6, #26
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  38              		.loc 1 133 0
  39 002a 85A230   		IF_E  mov	r2,#48
  40 002d 8AA231   		IF_NE mov	r2,#49
  41 0030 F9010C60 		test	r6,#0x1 wz
 137:Demo2.c       ****     (BD(u, 1, pin_P25)  ? '1' : '0'),  // P25
  42              		.loc 1 137 0
  43 0034 0A67     		mov	r6, r7
  44 0036 3619A0   		shr	r6, #25
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  45              		.loc 1 133 0
  46 0039 85A330   		IF_E  mov	r3,#48
  47 003c 8AA331   		IF_NE mov	r3,#49
  48 003f F9010C60 		test	r6,#0x1 wz
 138:Demo2.c       ****     (BD(u, 1, pin_RW)   ? 'R' : 'W'),  // !R/W
  49              		.loc 1 138 0
  50 0043 0A67     		mov	r6, r7
  51 0045 3618A0   		shr	r6, #24
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  52              		.loc 1 133 0
  53 0048 85A430   		IF_E  mov	r4,#48
  54 004b 8AA431   		IF_NE mov	r4,#49
  55 004e F9010C60 		test	r6,#0x1 wz
  56 0052 660000   		mviw	r6,#.LC0
  57 0055 85A557   		IF_E  mov	r5,#87
  58 0058 8AA552   		IF_NE mov	r5,#82
  59 005b F0100C08 		wrlong	r6, sp
  60 005f C604     		leasp r6,#4
  61 0061 116F     		wrlong	r1, r6
  62 0063 2640     		add	r6, #4
  63 0065 126F     		wrlong	r2, r6
  64 0067 2640     		add	r6, #4
  65 0069 136F     		wrlong	r3, r6
  66 006b 2640     		add	r6, #4
  67 006d 146F     		wrlong	r4, r6
  68 006f 2640     		add	r6, #4
  69 0071 156F     		wrlong	r5, r6
 139:Demo2.c       ****     get_ADDR(u),                       // Address bus
  70              		.loc 1 139 0
  71 0073 E66789   		xmov	r6,r7 shl r6,#8
 133:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
  72              		.loc 1 133 0
  73 0076 C518     		leasp r5,#24
  74 0078 3610A0   		shr	r6, #16
  75 007b 37FF40   		and	r7, #255
  76              	.LVL1
  77 007e 165F     		wrlong	r6, r5
  78 0080 C61C     		leasp r6,#28
  79 0082 176F     		wrlong	r7, r6
  80 0084 060000   		lcall	#_dprint
 140:Demo2.c       ****     get_DATA(u));                      // Data bus
 141:Demo2.c       ****     
 142:Demo2.c       ****   // Not shown are
 143:Demo2.c       ****   // - P31/P30 (serial port, so changes all the time)
 144:Demo2.c       ****   // - P29 (EEPROM data line, always high)
 145:Demo2.c       **** }
  81              		.loc 1 145 0
  82 0087 0C20     		add	sp, #32
  83 0089 051F     		lpopret	#16+15
  84              	.LFE1
  85              		.global	_memorycog
  86              	_memorycog
  87              	.LFB2
 146:Demo2.c       **** 
 147:Demo2.c       **** 
 148:Demo2.c       **** //---------------------------------------------------------------------------
 149:Demo2.c       **** // Memory cog
 150:Demo2.c       **** void memorycog()
 151:Demo2.c       **** {
  88              		.loc 1 151 0
  89              	.LBB2
 152:Demo2.c       ****   for(;;)
 153:Demo2.c       ****   {
 154:Demo2.c       ****     // Wait until the clock goes low
 155:Demo2.c       ****     waitpeq(0, BP(pin_CLK0));
  90              		.loc 1 155 0
  91 008b B6       		mov	r6, #0
  92 008c 57000000 		mvi	r7,#268435456
  92      10
  93              	.L13
  94              		.loc 1 155 0 is_stmt 0 discriminator 1
  95 0091 F0070CF0 		waitpeq	r6,r7
 156:Demo2.c       ****     
 157:Demo2.c       ****     // If we put anything on the data bus, take it off now
 158:Demo2.c       ****     set_DATA(DIRA, 0);
  96              		.loc 1 158 0 is_stmt 1 discriminator 1
  97 0095 F2000AA0 		mov	r5, DIRA
 159:Demo2.c       ****     
 160:Demo2.c       ****     // Get the address and check if it's in range
 161:Demo2.c       ****     unsigned addr = get_ADDR(INA);
  98              		.loc 1 161 0 discriminator 1
  99 0099 F2000AA0 		mov	r5, INA
 100 009d 7FF2     		brs	#.L13
 101              	.LBE2
 102              	.LFE2
 103              		.data
 104              		.balign	4
 105              	.LC1
 106 0018 48656C6C 		.ascii "Hello L-Star!\12\0"
 106      6F204C2D 
 106      53746172 
 106      210A00
 107 0027 00       		.text
 108              		.global	_main
 109              	_main
 110              	.LFB3
 162:Demo2.c       ****   }    
 163:Demo2.c       **** }
 164:Demo2.c       **** 
 165:Demo2.c       ****   
 166:Demo2.c       **** //---------------------------------------------------------------------------
 167:Demo2.c       **** // Main function
 168:Demo2.c       **** int main()
 169:Demo2.c       **** {
 111              		.loc 1 169 0
 112 009f 033D     		lpushm	#(3<<4)+13
 113              	.LCFI2
 114 00a1 0CFC     		sub	sp, #4
 115              	.LCFI3
 170:Demo2.c       ****   // Close the default same-cog terminal so it doesn't interfere,
 171:Demo2.c       ****   // and start a full-duplex terminal on another cog.
 172:Demo2.c       ****   simpleterm_close();
 173:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 116              		.loc 1 173 0
 117 00a3 6E0000   		mviw	r14,#_term
 118              	.LBB3
 174:Demo2.c       **** 
 175:Demo2.c       ****   // The clock of the 65C02 is shared with the SCL clock line of the I2C
 176:Demo2.c       ****   // bus that's connected to the EEPROM that holds the Propeller firmware.
 177:Demo2.c       ****   // We need to keep SDA High to keep the EEPROM from activating, and we
 178:Demo2.c       ****   // need to set the direction for the SCL / CLK0 to OUTPUT so we can
 179:Demo2.c       ****   // clock the 6502. There are two pull-up resistors that pull the lines
 180:Demo2.c       ****   // High until we do this, so if we make sure the output is set to High
 181:Demo2.c       ****   // before we set the set the direction to output, nothing bad will
 182:Demo2.c       ****   // happen.
 183:Demo2.c       ****   OUTA |= (BP(pin_SDA) | BP(pin_CLK0));
 184:Demo2.c       ****   DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
 185:Demo2.c       ****   
 186:Demo2.c       ****   // Initialization done
 187:Demo2.c       ****   dprint(term, "Hello L-Star!\n");
 188:Demo2.c       **** 
 189:Demo2.c       ****   for(;;)
 190:Demo2.c       ****   {
 191:Demo2.c       ****     int c = fdserial_rxTime(term, 500);
 192:Demo2.c       ****     
 193:Demo2.c       ****     switch (c)
 194:Demo2.c       ****     {
 195:Demo2.c       ****     case 'c':
 196:Demo2.c       ****     case 'C':
 197:Demo2.c       ****       // Toggle the clock
 198:Demo2.c       ****       OUTA ^= BP(pin_CLK0);
 119              		.loc 1 198 0
 120 00a6 5D000000 		mvi	r13,#268435456
 120      10
 121              	.LBE3
 172:Demo2.c       ****   simpleterm_close();
 122              		.loc 1 172 0
 123 00ab 060000   		lcall	#_simpleterm_close
 173:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 124              		.loc 1 173 0
 125 00ae A11E     		mov	r1, #30
 126 00b0 B2       		mov	r2, #0
 127 00b1 5300C201 		mvi	r3,#115200
 127      00
 128 00b6 A01F     		mov	r0, #31
 129 00b8 060000   		lcall	#_fdserial_open
 183:Demo2.c       ****   OUTA |= (BP(pin_SDA) | BP(pin_CLK0));
 130              		.loc 1 183 0
 131 00bb F2000EA0 		mov	r7, OUTA
 132              	.LVL2
 133 00bf 56000000 		mvi	r6,#805306368
 133      30
 134 00c4 1767     		or	r7, r6
 135              	.LVL3
 136 00c6 F20700A0 		mov	OUTA, r7
 137              	.LVL4
 184:Demo2.c       ****   DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
 138              		.loc 1 184 0
 139 00ca F2000EA0 		mov	r7, DIRA
 140              	.LVL5
 141 00ce 1767     		or	r7, r6
 142              	.LVL6
 143 00d0 F20700A0 		mov	DIRA, r7
 144              	.LVL7
 187:Demo2.c       ****   dprint(term, "Hello L-Star!\n");
 145              		.loc 1 187 0
 146 00d4 670000   		mviw	r7,#.LC1
 147              	.LVL8
 173:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 148              		.loc 1 173 0
 149 00d7 10EF     		wrlong	r0, r14
 187:Demo2.c       ****   dprint(term, "Hello L-Star!\n");
 150              		.loc 1 187 0
 151 00d9 F0100E08 		wrlong	r7, sp
 152 00dd 060000   		lcall	#_dprint
 153              	.L18
 154              	.LBB4
 191:Demo2.c       ****     int c = fdserial_rxTime(term, 500);
 155              		.loc 1 191 0
 156 00e0 10ED     		rdlong	r0, r14
 157 00e2 61F401   		mov	r1, #500
 158 00e5 060000   		lcall	#_fdserial_rxTime
 159              	.LVL9
 193:Demo2.c       ****     switch (c)
 160              		.loc 1 193 0
 161 00e8 304320   		cmps	r0, #67 wz,wc
 162 00eb 7A05     		IF_E 	brs	#.L16
 163 00ed 306320   		cmps	r0, #99 wz,wc
 164 00f0 75EE     		IF_NE	brs	#.L18
 165              	.L16
 166              		.loc 1 198 0
 167 00f2 F2000EA0 		mov	r7, OUTA
 168              	.LVL10
 169 00f6 17D8     		xor	r7, r13
 170              	.LVL11
 171 00f8 F20700A0 		mov	OUTA, r7
 172              	.LVL12
 199:Demo2.c       ****       break;
 200:Demo2.c       ****       
 201:Demo2.c       ****     default:
 202:Demo2.c       ****       continue;
 203:Demo2.c       ****     }
 204:Demo2.c       ****     
 205:Demo2.c       ****     // Print the state of the pins
 206:Demo2.c       ****     print_ina();
 173              		.loc 1 206 0
 174 00fc 060000   		lcall	#_print_ina
 175              	.LVL13
 176 00ff 7FDF     		brs	#.L18
 177              	.LBE4
 178              	.LFE3
 179              		.comm	_term,4,4
 241              	.Letext0
 242              		.file 2 "C:/Users/Jac/Documents/SimpleIDE/Learn/Simple Libraries/TextDevices/libsimpletext/simplet
 243              		.file 3 "c:\\program files (x86)\\simpleide\\propeller-gcc\\bin\\../lib/gcc/propeller-elf/4.6.1/..
DEFINED SYMBOLS
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:2      .text:00000000 .Ltext0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:5      .data:00000000 .LC0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:9      .text:00000000 _print_ina
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:10     .text:00000000 .LFB1
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:13     .text:00000000 L0
                            *COM*:00000004 _term
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:84     .text:0000008b .LFE1
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:86     .text:0000008b _memorycog
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:87     .text:0000008b .LFB2
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:89     .text:0000008b .LBB2
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:101    .text:0000009f .LBE2
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:102    .text:0000009f .LFE2
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:105    .data:00000018 .LC1
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:109    .text:0000009f _main
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:110    .text:0000009f .LFB3
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:178    .text:00000101 .LFE3
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:181    .debug_frame:00000000 .Lframe0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:241    .text:00000101 .Letext0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:245    .debug_info:00000000 .Ldebug_info0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:636    .debug_abbrev:00000000 .Ldebug_abbrev0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:973    .debug_loc:00000000 .LLST0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:986    .debug_loc:00000020 .LLST1
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:993    .debug_loc:00000033 .LLST2
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:1011   .debug_loc:0000005f .LLST3
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:1031   .debug_ranges:00000000 .Ldebug_ranges0
C:\Users\Jac\AppData\Local\Temp\ccofvCYq.s:1039   .debug_line:00000000 .Ldebug_line0

UNDEFINED SYMBOLS
INA
_dprint
DIRA
_simpleterm_close
_fdserial_open
OUTA
_fdserial_rxTime
