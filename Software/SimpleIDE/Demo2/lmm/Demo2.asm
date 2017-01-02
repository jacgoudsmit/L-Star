 GNU assembler version 2.21 (propeller-elf)
	 using BFD version (propellergcc_v1_0_0_2408) 2.21.
 options passed	: -lmm -ahdlnsg=lmm/Demo2.asm 
 input file    	: C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s
 output file   	: lmm/Demo2.o
 target        	: propeller-parallax-elf
 time stamp    	: 

   1              		.text
   2              	.Ltext0
   3              		.balign	4
   4              		.global	_memorycog
   5              	_memorycog
   6              	.LFB2
   7              		.file 1 "Demo2.c"
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
  49:Demo2.c       **** #define set_DATA(x, v) do { x = BI(x, v, 8, pin_D0); } while (0)
  50:Demo2.c       **** 
  51:Demo2.c       **** // Decode the address bus
  52:Demo2.c       **** // Example: dprint(term, "%X", get_ADDR(INA))
  53:Demo2.c       **** #define get_ADDR(x) BD(x, 16, pin_A0)
  54:Demo2.c       **** 
  55:Demo2.c       **** 
  56:Demo2.c       **** #define ROMSIZE (0x10)
  57:Demo2.c       **** #define RAMSIZE (0x300)
  58:Demo2.c       **** 
  59:Demo2.c       **** 
  60:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  61:Demo2.c       **** // TYPES
  62:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
  63:Demo2.c       **** 
  64:Demo2.c       **** 
  65:Demo2.c       **** // Mnemonics for all pins
  66:Demo2.c       **** typedef enum
  67:Demo2.c       **** {
  68:Demo2.c       ****   // Data bus
  69:Demo2.c       ****   pin_D0,
  70:Demo2.c       ****   pin_D1,
  71:Demo2.c       ****   pin_D2,
  72:Demo2.c       ****   pin_D3,
  73:Demo2.c       ****   pin_D4,
  74:Demo2.c       ****   pin_D5,
  75:Demo2.c       ****   pin_D6,
  76:Demo2.c       ****   pin_D7,
  77:Demo2.c       ****   
  78:Demo2.c       ****   // Address bus
  79:Demo2.c       ****   pin_A0,
  80:Demo2.c       ****   pin_A1,
  81:Demo2.c       ****   pin_A2,
  82:Demo2.c       ****   pin_A3,
  83:Demo2.c       ****   pin_A4,
  84:Demo2.c       ****   pin_A5,
  85:Demo2.c       ****   pin_A6,
  86:Demo2.c       ****   pin_A7,
  87:Demo2.c       ****   pin_A8,
  88:Demo2.c       ****   pin_A9,
  89:Demo2.c       ****   pin_A10,
  90:Demo2.c       ****   pin_A11,
  91:Demo2.c       ****   pin_A12,
  92:Demo2.c       ****   pin_A13,
  93:Demo2.c       ****   pin_A14,
  94:Demo2.c       ****   pin_A15,
  95:Demo2.c       ****   
  96:Demo2.c       ****   // Read/Not Write
  97:Demo2.c       ****   pin_RW,
  98:Demo2.c       ****   
  99:Demo2.c       ****   // Uncommitted I/O pins
 100:Demo2.c       ****   pin_P25,
 101:Demo2.c       ****   pin_P26,
 102:Demo2.c       ****   pin_P27,
 103:Demo2.c       ****   
 104:Demo2.c       ****   // I2C bus
 105:Demo2.c       ****   pin_CLK0,
 106:Demo2.c       ****   pin_SDA,
 107:Demo2.c       ****   
 108:Demo2.c       ****   // Serial port
 109:Demo2.c       ****   pin_TX,
 110:Demo2.c       ****   pin_RX
 111:Demo2.c       ****   
 112:Demo2.c       **** } pin;
 113:Demo2.c       **** 
 114:Demo2.c       **** 
 115:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 116:Demo2.c       **** // DATA
 117:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 118:Demo2.c       **** 
 119:Demo2.c       **** 
 120:Demo2.c       **** // Pointer to use for terminal calls.
 121:Demo2.c       **** terminal *term;
 122:Demo2.c       **** 
 123:Demo2.c       **** // ROM and RAM
 124:Demo2.c       **** uint8_t ROMRAM[ROMSIZE + RAMSIZE] = {
 125:Demo2.c       ****   // $FFF0
 126:Demo2.c       ****   0xEE, 0x00, 0x02,   // inc $200
 127:Demo2.c       ****   0x4C, 0xF0, 0xFF,   // jmp $FFF0
 128:Demo2.c       ****   
 129:Demo2.c       ****   0x00, 0x00, 0x00, 0x00, // filler bytes
 130:Demo2.c       ****   
 131:Demo2.c       ****   // $FFFA
 132:Demo2.c       ****   0xF0, 0xFF,         // NMI vector
 133:Demo2.c       ****   0xF0, 0xFF,         // Reset vector
 134:Demo2.c       ****   0xF0, 0xFF          // BRK / IRQ vector
 135:Demo2.c       ****   
 136:Demo2.c       ****   // Rest of the array is filled with 0x00 by the compiler
 137:Demo2.c       **** };
 138:Demo2.c       **** 
 139:Demo2.c       **** 
 140:Demo2.c       ****   
 141:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 142:Demo2.c       **** // FUNCTIONS
 143:Demo2.c       **** /////////////////////////////////////////////////////////////////////////////
 144:Demo2.c       **** 
 145:Demo2.c       **** 
 146:Demo2.c       **** //---------------------------------------------------------------------------
 147:Demo2.c       **** // Print the pins
 148:Demo2.c       **** void print_ina(void)
 149:Demo2.c       **** {
 150:Demo2.c       ****   unsigned u = INA;
 151:Demo2.c       ****   
 152:Demo2.c       ****   // Show the PHI2 output to the 6502, the three I/O lines P27/P26/P25,
 153:Demo2.c       ****   // the R/!W line, the address bus and the data bus.
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 155:Demo2.c       ****     (BD(u, 1, pin_CLK0) ? 'H' : 'L'),  // CLK
 156:Demo2.c       ****     (BD(u, 1, pin_P27)  ? '1' : '0'),  // P27 (e.g. !RAMEN)
 157:Demo2.c       ****     (BD(u, 1, pin_P26)  ? '1' : '0'),  // P26
 158:Demo2.c       ****     (BD(u, 1, pin_P25)  ? '1' : '0'),  // P25
 159:Demo2.c       ****     (BD(u, 1, pin_RW)   ? 'R' : 'W'),  // !R/W
 160:Demo2.c       ****     get_ADDR(u),                       // Address bus
 161:Demo2.c       ****     get_DATA(u));                      // Data bus
 162:Demo2.c       ****     
 163:Demo2.c       ****   // Not shown are
 164:Demo2.c       ****   // - P31/P30 (serial port, so changes all the time)
 165:Demo2.c       ****   // - P29 (EEPROM data line, always high)
 166:Demo2.c       **** }
 167:Demo2.c       **** 
 168:Demo2.c       **** 
 169:Demo2.c       **** //---------------------------------------------------------------------------
 170:Demo2.c       **** // Memory cog
 171:Demo2.c       **** void memorycog()
 172:Demo2.c       **** {
   8              		.loc 1 172 0
   9 0000 0400FC84 		sub	sp, #4
  10              	.LCFI0
  11 0004 00003C08 		wrlong	lr, sp
  12              	.LCFI1
  13              	.LBB2
 173:Demo2.c       ****   for(;;)
 174:Demo2.c       ****   {
 175:Demo2.c       ****     // Wait until the clock goes low
 176:Demo2.c       ****     waitpeq(0, BP(pin_CLK0));
  14              		.loc 1 176 0
  15 0008 0000FCA0 		mov	r4, #0
  16 000c 00007C5C 		mvi	r5,#268435456
  16      00000010 
 177:Demo2.c       ****     
 178:Demo2.c       ****     // If we put anything on the data bus in the previous cycle, take it off.
 179:Demo2.c       ****     set_DATA(DIRA, 0);
 180:Demo2.c       ****     
 181:Demo2.c       ****     // Get the address and check if it's in range
 182:Demo2.c       ****     unsigned addr = get_ADDR(INA);
  17              		.loc 1 182 0
  18 0014 00007C5C 		mvi	r0,#16776960
  18      00FFFF00 
 183:Demo2.c       ****     
 184:Demo2.c       ****     // Calculate offset in array
 185:Demo2.c       ****     addr = (addr + ROMSIZE) & 0xFFFF;
  19              		.loc 1 185 0
  20 001c 00007C5C 		mvi	r1,#65535
  20      FFFF0000 
 186:Demo2.c       ****     
 187:Demo2.c       ****     // Wait until the clock goes high
 188:Demo2.c       ****     waitpne(0, BP(pin_CLK0));
 189:Demo2.c       **** 
 190:Demo2.c       ****     // Check if the address is in range    
 191:Demo2.c       ****     if (addr < sizeof(ROMRAM))
  21              		.loc 1 191 0
  22 0024 00007C5C 		mvi	r2,#783
  22      0F030000 
 192:Demo2.c       ****     {
 193:Demo2.c       ****       // Check for read or write mode
 194:Demo2.c       ****       if (BD(INA, 1, pin_RW))
  23              		.loc 1 194 0
  24 002c 00007C5C 		mvi	r3,#16777216
  24      00000001 
 195:Demo2.c       ****       {
 196:Demo2.c       ****         // The 65C02 is reading, put data from the array on the data bus
 197:Demo2.c       ****         OUTA = (unsigned)ROMRAM[addr];
 198:Demo2.c       ****         set_DATA(DIRA, 0xFF);
 199:Demo2.c       ****       }
 200:Demo2.c       ****       else
 201:Demo2.c       ****       {
 202:Demo2.c       ****         // The 6502 is writing. Make sure we don't overwrite the ROM
 203:Demo2.c       ****         if (addr >= ROMSIZE)
 204:Demo2.c       ****         {
 205:Demo2.c       ****           ROMRAM[addr] = (uint8_t)INA;
  25              		.loc 1 205 0
  26 0034 00007C5C 		mvi	r6,#_ROMRAM
  26      00000000 
  27              	.LVL0
  28 003c 00007C5C 		jmp	#__LMM_FCACHE_LOAD
  29 0040 74000000 		long	.L9-.L8
  30              	.L8
  31              	.L7
 176:Demo2.c       ****     waitpeq(0, BP(pin_CLK0));
  32              		.loc 1 176 0
  33 0044 00003CF0 		waitpeq	r4,r5
 179:Demo2.c       ****     set_DATA(DIRA, 0);
  34              		.loc 1 179 0
  35 0048 0000BCA0 		mov	r7, DIRA
  36 004c FF00FC64 		andn	r7, #0xff
  37              	.LVL1
  38 0050 0000BCA0 		mov	DIRA, r7
  39              	.LVL2
 182:Demo2.c       ****     unsigned addr = get_ADDR(INA);
  40              		.loc 1 182 0
  41 0054 0000BCA0 		mov	r7, INA
  42              	.LVL3
  43 0058 0000BC60 		and	r7, r0
  44              	.LVL4
  45 005c 0800FC28 		shr	r7, #8
 185:Demo2.c       ****     addr = (addr + ROMSIZE) & 0xFFFF;
  46              		.loc 1 185 0
  47 0060 1000FC80 		add	r7, #16
  48 0064 0000BC60 		and	r7, r1
  49              	.LVL5
 188:Demo2.c       ****     waitpne(0, BP(pin_CLK0));
  50              		.loc 1 188 0
  51 0068 00003CF4 		waitpne	r4,r5
 191:Demo2.c       ****     if (addr < sizeof(ROMRAM))
  52              		.loc 1 191 0
  53 006c 00003C87 		cmp	r7, r2 wz,wc
  54 0070 0000445C 		IF_A 	jmp	#__LMM_FCACHE_START+(.L7-.L8)
 194:Demo2.c       ****       if (BD(INA, 1, pin_RW))
  55              		.loc 1 194 0
  56 0074 0000BCA0 		mov	lr, INA
  57 0078 00003C62 		test	lr,r3 wz
  58 007c 0000685C 		IF_E 	jmp	#__LMM_FCACHE_START+(.L4-.L8)
 197:Demo2.c       ****         OUTA = (unsigned)ROMRAM[addr];
  59              		.loc 1 197 0
  60 0080 0000BC80 		add	r7, r6
  61              	.LVL6
  62 0084 0000BC00 		rdbyte	r7, r7
  63              	.LVL7
  64 0088 0000BCA0 		mov	OUTA, r7
  65              	.LVL8
 198:Demo2.c       ****         set_DATA(DIRA, 0xFF);
  66              		.loc 1 198 0
  67 008c 0000BCA0 		mov	r7, DIRA
  68              	.LVL9
  69 0090 FF00FC68 		or	r7, #255
  70              	.LVL10
  71 0094 0000BCA0 		mov	DIRA, r7
  72              	.LVL11
  73 0098 00007C5C 		jmp	#__LMM_FCACHE_START+(.L7-.L8)
  74              	.LVL12
  75              	.L4
 203:Demo2.c       ****         if (addr >= ROMSIZE)
  76              		.loc 1 203 0
  77 009c 0F007C87 		cmp	r7, #15 wz,wc
  78 00a0 0000785C 		IF_BE	jmp	#__LMM_FCACHE_START+(.L7-.L8)
  79              		.loc 1 205 0
  80 00a4 0000BCA0 		mov	lr, INA
  81 00a8 0000BC80 		add	r7, r6
  82              	.LVL13
  83 00ac 00003C00 		wrbyte	lr, r7
  84 00b0 00007C5C 		jmp	#__LMM_FCACHE_START+(.L7-.L8)
  85 00b4 00003C5C 		jmp	__LMM_RET
  86              		.compress default
  87              	.L9
  88              	.LBE2
  89              	.LFE2
  90              		.data
  91              		.balign	4
  92              	.LC0
  93 0000 25632025 		.ascii "%c %c%c%c %c %04x %02x\12\0"
  93      63256325 
  93      63202563 
  93      20253034 
  93      78202530 
  94              		.text
  95              		.balign	4
  96              		.global	_print_ina
  97              	_print_ina
  98              	.LFB1
 149:Demo2.c       **** {
  99              		.loc 1 149 0
 100 00b8 0400FC84 		sub	sp, #4
 101              	.LCFI2
 102 00bc 00003C08 		wrlong	lr, sp
 103              	.LCFI3
 104 00c0 2000FC84 		sub	sp, #32
 105              	.LCFI4
 150:Demo2.c       ****   unsigned u = INA;
 106              		.loc 1 150 0
 107 00c4 0000BCA0 		mov	r7, INA
 108              	.LVL14
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 109              		.loc 1 154 0
 110 00c8 00007C5C 		mvi	r6,#_term
 110      00000000 
 111 00d0 0000BC08 		rdlong	r0, r6
 155:Demo2.c       ****     (BD(u, 1, pin_CLK0) ? 'H' : 'L'),  // CLK
 112              		.loc 1 155 0
 113 00d4 0000BCA0 		mov	r6, r7
 114 00d8 1C00FC28 		shr	r6, #28
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 115              		.loc 1 154 0
 116 00dc 01007C62 		test	r6,#0x1 wz
 156:Demo2.c       ****     (BD(u, 1, pin_P27)  ? '1' : '0'),  // P27 (e.g. !RAMEN)
 117              		.loc 1 156 0
 118 00e0 0000BCA0 		mov	r6, r7
 119 00e4 1B00FC28 		shr	r6, #27
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 120              		.loc 1 154 0
 121 00e8 4C00E8A0 		IF_E  mov	r1,#76
 122 00ec 4800D4A0 		IF_NE mov	r1,#72
 123 00f0 01007C62 		test	r6,#0x1 wz
 157:Demo2.c       ****     (BD(u, 1, pin_P26)  ? '1' : '0'),  // P26
 124              		.loc 1 157 0
 125 00f4 0000BCA0 		mov	r6, r7
 126 00f8 1A00FC28 		shr	r6, #26
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 127              		.loc 1 154 0
 128 00fc 3000E8A0 		IF_E  mov	r2,#48
 129 0100 3100D4A0 		IF_NE mov	r2,#49
 130 0104 01007C62 		test	r6,#0x1 wz
 158:Demo2.c       ****     (BD(u, 1, pin_P25)  ? '1' : '0'),  // P25
 131              		.loc 1 158 0
 132 0108 0000BCA0 		mov	r6, r7
 133 010c 1900FC28 		shr	r6, #25
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 134              		.loc 1 154 0
 135 0110 3000E8A0 		IF_E  mov	r3,#48
 136 0114 3100D4A0 		IF_NE mov	r3,#49
 137 0118 01007C62 		test	r6,#0x1 wz
 159:Demo2.c       ****     (BD(u, 1, pin_RW)   ? 'R' : 'W'),  // !R/W
 138              		.loc 1 159 0
 139 011c 0000BCA0 		mov	r6, r7
 140 0120 1800FC28 		shr	r6, #24
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 141              		.loc 1 154 0
 142 0124 3000E8A0 		IF_E  mov	r4,#48
 143 0128 3100D4A0 		IF_NE mov	r4,#49
 144 012c 01007C62 		test	r6,#0x1 wz
 145 0130 00007C5C 		mvi	r6,#.LC0
 145      00000000 
 146 0138 5700E8A0 		IF_E  mov	r5,#87
 147 013c 5200D4A0 		IF_NE mov	r5,#82
 148 0140 00003C08 		wrlong	r6, sp
 149 0144 0000BCA0 		mov	r6, sp
 150 0148 0400FC80 		add	r6, #4
 151 014c 00003C08 		wrlong	r1, r6
 152 0150 0400FC80 		add	r6, #4
 153 0154 00003C08 		wrlong	r2, r6
 154 0158 0400FC80 		add	r6, #4
 155 015c 00003C08 		wrlong	r3, r6
 156 0160 0400FC80 		add	r6, #4
 157 0164 00003C08 		wrlong	r4, r6
 158 0168 0400FC80 		add	r6, #4
 159 016c 00003C08 		wrlong	r5, r6
 160:Demo2.c       ****     get_ADDR(u),                       // Address bus
 160              		.loc 1 160 0
 161 0170 0000BCA0 		mov	r6, r7
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 162              		.loc 1 154 0
 163 0174 0000BCA0 		mov	r5, sp
 160:Demo2.c       ****     get_ADDR(u),                       // Address bus
 164              		.loc 1 160 0
 165 0178 0800FC2C 		shl	r6, #8
 154:Demo2.c       ****   dprint(term, "%c %c%c%c %c %04x %02x\n", 
 166              		.loc 1 154 0
 167 017c 1800FC80 		add	r5, #24
 168 0180 1000FC28 		shr	r6, #16
 169 0184 FF00FC60 		and	r7, #255
 170              	.LVL15
 171 0188 00003C08 		wrlong	r6, r5
 172 018c 0000BCA0 		mov	r6, sp
 173 0190 1C00FC80 		add	r6, #28
 174 0194 00003C08 		wrlong	r7, r6
 175 0198 00007C5C 		lcall	#_dprint
 175      00000000 
 166:Demo2.c       **** }
 176              		.loc 1 166 0
 177 01a0 2000FC80 		add	sp, #32
 178 01a4 0000BC08 		rdlong	lr, sp
 179 01a8 0400FC80 		add	sp, #4
 180 01ac 0000BCA0 		mov	pc,lr
 181              	.LFE1
 182              		.data
 183              		.balign	4
 184              	.LC1
 185 0018 48656C6C 		.ascii "Hello L-Star!\12\0"
 185      6F204C2D 
 185      53746172 
 185      210A00
 186              		.text
 187              		.balign	4
 188              		.global	_main
 189              	_main
 190              	.LFB3
 206:Demo2.c       ****         }
 207:Demo2.c       ****       }
 208:Demo2.c       ****     }                        
 209:Demo2.c       ****   }    
 210:Demo2.c       **** }
 211:Demo2.c       **** 
 212:Demo2.c       ****   
 213:Demo2.c       **** //---------------------------------------------------------------------------
 214:Demo2.c       **** // Main function
 215:Demo2.c       **** int main()
 216:Demo2.c       **** {
 191              		.loc 1 216 0
 192 01b0 3D00FCA0 		mov	__TMP0,#(3<<4)+13
 193 01b4 0000FC5C 		call	#__LMM_PUSHM
 194              	.LCFI5
 195 01b8 0400FC84 		sub	sp, #4
 196              	.LCFI6
 217:Demo2.c       ****   // Close the default same-cog terminal so it doesn't interfere,
 218:Demo2.c       ****   // and start a full-duplex terminal on another cog.
 219:Demo2.c       ****   simpleterm_close();
 220:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 197              		.loc 1 220 0
 198 01bc 00007C5C 		mvi	r14,#_term
 198      00000000 
 199              	.LBB3
 221:Demo2.c       **** 
 222:Demo2.c       ****   // The clock of the 65C02 is shared with the SCL clock line of the I2C
 223:Demo2.c       ****   // bus that's connected to the EEPROM that holds the Propeller firmware.
 224:Demo2.c       ****   // We need to keep SDA High to keep the EEPROM from activating, and we
 225:Demo2.c       ****   // need to set the direction for the SCL / CLK0 to OUTPUT so we can
 226:Demo2.c       ****   // clock the 6502. There are two pull-up resistors that pull the lines
 227:Demo2.c       ****   // High until we do this, so if we make sure the output is set to High
 228:Demo2.c       ****   // before we set the set the direction to output, nothing bad will
 229:Demo2.c       ****   // happen.
 230:Demo2.c       ****   OUTA |= (BP(pin_SDA) | BP(pin_CLK0));
 231:Demo2.c       ****   DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
 232:Demo2.c       ****   
 233:Demo2.c       ****   // Start the memory cog
 234:Demo2.c       ****   cog_run(memorycog, 0);
 235:Demo2.c       **** 
 236:Demo2.c       ****   // Initialization done
 237:Demo2.c       ****   dprint(term, "Hello L-Star!\n");
 238:Demo2.c       **** 
 239:Demo2.c       ****   for(;;)
 240:Demo2.c       ****   {
 241:Demo2.c       ****     int c = fdserial_rxTime(term, 500);
 242:Demo2.c       ****     
 243:Demo2.c       ****     switch (c)
 244:Demo2.c       ****     {
 245:Demo2.c       ****     case 'c':
 246:Demo2.c       ****     case 'C':
 247:Demo2.c       ****       // Toggle the clock
 248:Demo2.c       ****       OUTA ^= BP(pin_CLK0);
 200              		.loc 1 248 0
 201 01c4 00007C5C 		mvi	r13,#268435456
 201      00000010 
 202              	.LBE3
 219:Demo2.c       ****   simpleterm_close();
 203              		.loc 1 219 0
 204 01cc 00007C5C 		lcall	#_simpleterm_close
 204      00000000 
 220:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 205              		.loc 1 220 0
 206 01d4 0000FCA0 		mov	r2, #0
 207 01d8 00007C5C 		mvi	r3,#115200
 207      00C20100 
 208 01e0 1E00FCA0 		mov	r1, #30
 209 01e4 1F00FCA0 		mov	r0, #31
 210 01e8 00007C5C 		lcall	#_fdserial_open
 210      00000000 
 230:Demo2.c       ****   OUTA |= (BP(pin_SDA) | BP(pin_CLK0));
 211              		.loc 1 230 0
 212 01f0 0000BCA0 		mov	r7, OUTA
 213              	.LVL16
 214 01f4 00007C5C 		mvi	r6,#805306368
 214      00000030 
 215 01fc 0000BC68 		or	r7, r6
 216              	.LVL17
 217 0200 0000BCA0 		mov	OUTA, r7
 218              	.LVL18
 231:Demo2.c       ****   DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
 219              		.loc 1 231 0
 220 0204 0000BCA0 		mov	r7, DIRA
 221              	.LVL19
 222 0208 0000BC68 		or	r7, r6
 223              	.LVL20
 234:Demo2.c       ****   cog_run(memorycog, 0);
 224              		.loc 1 234 0
 225 020c 0000FCA0 		mov	r1, #0
 231:Demo2.c       ****   DIRA |= (BP(pin_SDA) | BP(pin_CLK0));
 226              		.loc 1 231 0
 227 0210 0000BCA0 		mov	DIRA, r7
 228              	.LVL21
 220:Demo2.c       ****   term = fdserial_open(31, 30, 0, 115200);
 229              		.loc 1 220 0
 230 0214 00003C08 		wrlong	r0, r14
 234:Demo2.c       ****   cog_run(memorycog, 0);
 231              		.loc 1 234 0
 232 0218 00007C5C 		mvi	r0,#_memorycog
 232      00000000 
 233 0220 00007C5C 		lcall	#_cog_run
 233      00000000 
 234              	.LVL22
 237:Demo2.c       ****   dprint(term, "Hello L-Star!\n");
 235              		.loc 1 237 0
 236 0228 0000BC08 		rdlong	r0, r14
 237 022c 00007C5C 		mvi	r7,#.LC1
 237      00000000 
 238 0234 00003C08 		wrlong	r7, sp
 239 0238 00007C5C 		lcall	#_dprint
 239      00000000 
 240              	.L25
 241              	.LBB4
 241:Demo2.c       ****     int c = fdserial_rxTime(term, 500);
 242              		.loc 1 241 0
 243 0240 0000BC08 		rdlong	r0, r14
 244 0244 F401FCA0 		mov	r1, #500
 245 0248 00007C5C 		lcall	#_fdserial_rxTime
 245      00000000 
 246              	.LVL23
 243:Demo2.c       ****     switch (c)
 247              		.loc 1 243 0
 248 0250 43007CC3 		cmps	r0, #67 wz,wc
 249 0254 0800E880 		IF_E 	brs	#.L23
 250 0258 63007CC3 		cmps	r0, #99 wz,wc
 251 025c 2000D484 		IF_NE	brs	#.L25
 252              	.L23
 253              		.loc 1 248 0
 254 0260 0000BCA0 		mov	r7, OUTA
 255              	.LVL24
 256 0264 0000BC6C 		xor	r7, r13
 257              	.LVL25
 258 0268 0000BCA0 		mov	OUTA, r7
 259              	.LVL26
 249:Demo2.c       ****       break;
 250:Demo2.c       ****       
 251:Demo2.c       ****     default:
 252:Demo2.c       ****       continue;
 253:Demo2.c       ****     }
 254:Demo2.c       ****     
 255:Demo2.c       ****     // Print the state of the pins
 256:Demo2.c       ****     print_ina();
 260              		.loc 1 256 0
 261 026c 00007C5C 		lcall	#_print_ina
 261      00000000 
 262              	.LVL27
 263 0274 3800FC84 		brs	#.L25
 264              	.LBE4
 265              	.LFE3
 266              		.global	_ROMRAM
 267              		.data
 268 0027 00       		.balign	4
 269              	_ROMRAM
 270 0028 EE       		byte	-18
 271 0029 00       		byte	0
 272 002a 02       		byte	2
 273 002b 4C       		byte	76
 274 002c F0       		byte	-16
 275 002d FF       		byte	-1
 276 002e 00       		byte	0
 277 002f 00       		byte	0
 278 0030 00       		byte	0
 279 0031 00       		byte	0
 280 0032 F0       		byte	-16
 281 0033 FF       		byte	-1
 282 0034 F0       		byte	-16
 283 0035 FF       		byte	-1
 284 0036 F0       		byte	-16
 285 0037 FF       		byte	-1
 286 0038 00000000 		.zero	768
 286      00000000 
 286      00000000 
 286      00000000 
 286      00000000 
 287              		.comm	_term,4,4
 363              	.Letext0
 364              		.file 2 "C:/Users/Jac/Documents/SimpleIDE/Learn/Simple Libraries/TextDevices/libsimpletext/simplet
 365              		.file 3 "c:\\program files (x86)\\simpleide\\propeller-gcc\\bin\\../lib/gcc/propeller-elf/4.6.1/..
 366              		.file 4 "c:\\program files (x86)\\simpleide\\propeller-gcc\\bin\\../lib/gcc/propeller-elf/4.6.1/..
DEFINED SYMBOLS
C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s:5      .text:00000000 _memorycog
C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s:9      .text:00000000 L0
C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s:269    .data:00000028 _ROMRAM
C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s:97     .text:000000b8 _print_ina
                            *COM*:00000004 _term
C:\Users\Jac\AppData\Local\Temp\ccZGOjRc.s:189    .text:000001b0 _main
                            .data:00000000 .LC0
                            .data:00000018 .LC1
                     .debug_frame:00000000 .Lframe0
                            .text:00000000 .LFB2
                            .text:000000b8 .LFE2
                            .text:000000b8 .LFB1
                            .text:000001b0 .LFB3
                    .debug_abbrev:00000000 .Ldebug_abbrev0
                            .text:00000000 .Ltext0
                            .text:00000278 .Letext0
                      .debug_line:00000000 .Ldebug_line0
                       .debug_loc:00000000 .LLST0
                            .text:00000008 .LBB2
                            .text:000000b8 .LBE2
                       .debug_loc:00000020 .LLST1
                            .text:000001b0 .LFE1
                       .debug_loc:00000053 .LLST2
                       .debug_loc:0000007f .LLST3
                            .text:00000278 .LFE3
                       .debug_loc:00000092 .LLST4
                    .debug_ranges:00000000 .Ldebug_ranges0
                       .debug_loc:000000be .LLST5
                      .debug_info:00000000 .Ldebug_info0

UNDEFINED SYMBOLS
sp
lr
r4
__LMM_MVI_r5
__LMM_MVI_r0
__LMM_MVI_r1
__LMM_MVI_r2
__LMM_MVI_r3
__LMM_MVI_r6
__LMM_FCACHE_LOAD
r5
r7
DIRA
INA
r0
r1
r2
__LMM_FCACHE_START
r3
r6
OUTA
__LMM_RET
__LMM_CALL
_dprint
pc
__TMP0
__LMM_PUSHM
__LMM_PUSHM_ret
__LMM_MVI_r14
__LMM_MVI_r13
_simpleterm_close
_fdserial_open
r14
_cog_run
__LMM_MVI_r7
_fdserial_rxTime
r13
