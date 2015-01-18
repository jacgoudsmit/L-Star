'' +--------------------------------------------------------------------------+
'' | One Pin TV Text Driver                                             v1.2x |
'' +--------------------------------------------------------------------------|
'' |  Authors:  (c) 2009 Eric Ball                        (original 1-pinTV)  |
'' |            (c) 2010 "Cluso99" (Ray Rodrick)          (almost rewrite)    |
'' |            (c) 2013 Jac Goudsmit                     (8-bit font)        |
'' |  License   MIT License - See end of file for terms of use                |
'' +--------------------------------------------------------------------------|
'' |  Forum:    http://forums.parallax.com/forums/default.aspx?f=25&m=431556  |
'' +--------------------------------------------------------------------------+
'' Original One Pin TV Text Driver demo (C) 2009-07-09 Eric Ball
'' Modified/rewritten by Cluso99
'' Further modified by Jac Goudsmit
''
'' Jac Goudsmit's modifications:
'' - It uses a 256 character font instead of the original 128 character font
'' - That means the font is stored in the hub and can't be overwritten unlike
''   the previous version: it takes up 2K which is too big to store it in
''   the cog
'' - This also means that the timing is a little more constrained, so with a
''   5MHz crystal, no display widths over 64 characters are supported
''   (PAL mode was not tested)
'' - It uses the assembler code in the hub for the screen buffer. This sorta
''   makes up for the fact that the font can no longer be regarded as
''   discardable garbage now
'' - Some constants and code were added to make it possible to let the driver
''   only use part of the screen buffer. You now set a screen width and height,
''   and a memory width and height which can be larger than the screen size. A
''   left margin and top margin are also set in the constants to make the
''   screen start at a memory offset other than 0.
'' - The mini-terminal code (which also generated the cursor) was removed; they
''   weren't needed in my project, and the functions can easily be implemented
''   as a separate module in Spin or Assembler that format the text into the
''   screen buffer as fast as it can. Keep in mind that the buffer size may not
''   be equal to the screen size (see previous point). Hint: try my
''   ScreenBufferText module included in this archive.
'' TO DO:
'' - I want to store and read some of the constants from hub memory and
''   re-retrieve them during the vertical sync, so it's possible to change the
''   parameters while the system is running.
''
'' RR20100214   _rr015  working for 64x28 NTSC & 64x32 PAL @5MHz
''                        added debug to show calculated values
'' RR20100215   _rr016  remove msb font mode (if reqd, reverse the font in hub)
''              _rr017  remove standby check & function (i.e. do setup once only)
''              _rr018
''              _rr019  use cog screen buffer 1024 bytes (64x16)
''              _rr020  cog screen buffer (40x16)
'' RR20100219   _rr022  cog font (only lsb font supported)
''                       (works but short of font space)
''              _rr023  add inverse bit8
''              _rr025  remove calcs, fix for 5MHz 40x25 chars, ok
''                      test release
''              _rr026  remove all parameter calcs (use "1pinTV_calcs.spin" to calculate parameters)
''              _rr027  add ASCII subset to cog (not VT100) 
''              _rr033  cls, bs, cr, lf working except does not scroll
'' RR20100220   _rr035  add flashing cursor, can, home, right, left, up, down (left/right bug)
''              _rr037  scroll, left, right working :-)
''              _rr038  test with 1-pin Keyboard
''              _rr040  automatically set for 5MHz,6.25, 6.5, 13.5MHz xtal values for ifrqa in xfrqa
'' RR20100226   _rr041  tested ok.
'' RR20100228   Debug version: Rename "Debug_1pinTV.spin" and modify.
''              Output methods: chr/out/tx, str, dec, hex
'' RR20100302   v1.01   add PAL parameters
'' RR20100304   v1.02   modify font to speed up pix generation (each long is stored in a seperate half font)
''                       saved 2 instrctions in :active loop
''              v1.03   add constants for 64x25 & 80x25 NTSC and test various clock frequencies
'' RR20100306   v1.04   remove double height option
'' RR20100315   v1.05   change call doblank2 -> doblank (saves space) at lines 1797
''                      movs vscl,xsync & movs vscl,xbackp s/be mov
'' RR20100318   v1.06   use hub TV cog code for screen buffer
''                        (note that for 80*25 DAT will need extending to prevent overwrite)
'' RR20100318   v1.07   DAT extended to take care in case screen is 80*25
'' RR20100318   v1.08   add methods clear, home, gotoxy, cr (in spin)
'' RR20100424   v1.10   improve documentation only
'' RR20100503   _rr050  code mods (MOVS VSCL,#...); new NTSC timing
''                      move vt100 tasks to blank line code
'' RR20100505   v1.20   include automatic parameter calculation as well as predefined versions
''                        add timing diagram
'' RR20100505   _rr051  code shrink for VT100 space; allow variable row size & fill hub when required;
''                      auto clear screen at start (reqd)
'' RR20100505   v1.25   release
'' JG20130309   n/a     Modified for 8-bit font in hub, and removed terminal code
''
''
' -------------------------------------------------------------------------------------------------
' * This routine displays 40/64 characters by 25 lines using an 8x8 pixel 256 character text font.
' * Other screen sizes are permitted.
' * NTSC or PAL can be selected.
' * Only 1 propeller pin is used with a simple series resistor to give TV B&W video out.
' * The font is accessed via a pointer that's stored into the code before starting it. The font
'   data needs to remain available during the life of the cog.
' * The screen buffer may resides in hub re-using the codespace originaly occupied by the cog code,
'    resulting in a minimum hub footprint. If this feature is used, the cog cannot started more
'    than once.
' * The user program is expected to write to the screen buffer directly.
' -------------------------------------------------------------------------------------------------

' -------------------------------------------------------------------------------------------------
' 1-pin composite video (TV) circuit...
' Acknowledgement: Phil Pilgrim for the circuit and Eric Ball for the original driver
'
'                  *see http://forums.parallax.com/forums/default.aspx?f=25&m=340731&g=342216
'
' Note: * 1 pin works with any TV resistor (100R .. 1K1) without the RC network although 270R is preferred.
'       * If you want to try this out, you can use the existing video circuitry (TV) without change.
'       * Practice has shown that the capacitor and pulldown resistor aren't needed
'       * See the Propeller Forum http://forums.parallax.com/forums/default.aspx?f=25&m=431556 for
'          more information including how to build a cable.
' -------------------------------------------------------------------------------------------------
' To use this routine in your program, simply add the following...
' OBJ
'   tv    :      "1pinTV256"
'   font  :      "<font module>" ' Module must have a GetPtrToFontTable function to get mirrored font
' PUB main | screenptr
'   screenptr := tv.start(tvPinc, font.GetPtrToFontTable)
' -------------------------------------------------------------------------------------------------

CON

'--------------------------------------------------------------------------------------------------

'' This is the "auto version"...
''   Just set the following parameters and the rest will be calculated automatically.
''
PAL                     =       0                       ' 0 = NTSC, 1 = PAL (PAL not fully tested))
oscreencols             =       25                      ' number of visible columns (MAX=64 @80MHz) (at most omemcols)
omemcols                =       32                      ' number of columns in memory (MAXIMUM =80?); must be multiple of 4
oscreenrows             =       25                      ' number of visible rows (MAXIMUM NTSC=28, PAL=32)
omemrows                =       32                      ' number of rows in memory 
oleftmargin             =       4                       ' number of hidden columns on left
otopmargin              =       4                       ' number of hidden rows on top
                         
'--------------------------------------------------------------------------------------------------

''
'' The following are calculated automatically.
ofrqa                   =       ocolsfrq * oscreencols * 8                            'PLLA CTRA Freq
ohalf                   =       ofrqa / linefrq / 2                             'ohalf
osync                   =       tsync / 100 * ofrqa / 1_000_000_0
t1                      =       tbackp / 100 * ofrqa / 1_000_000_0              'back porch min time
t2                      =       tfrontp / 100 * ofrqa / 1_000_000_0             'front porch min time
'now average the remaining line time between back porch and front porch
obackp                  =       (ohalf + ohalf - osync - t1 - (oscreencols * 8) - t2) / 2 + t1  'back porch
plldiv                  =       >|((ofrqa - 1) / 1_000_000)                     'determine PLLDIV
ictra                   =       (%00001 << 3) | plldiv                          'ctrmode + plldiv (internal video mode)
linefrq                 =       (15_734 * (1-PAL)) + (15_625 * PAL)   ' Line Freq (NTSC=15.734KHz, PAL=15.625KHz)
ocolsfrq                =       (22_478 * (1-PAL)) + (22_321 * PAL)   ' Hz per active pixel (NTSC=22478, PAL=22321)
linesh                  =       (525 / 2 * (1-PAL)) + (625 / 2 * PAL) ' lines per frame (NTSC=262, PAL=312)
tsync                   =       4700                                  ' time (ns) of sync pulse (4.7us)
tbackp                  =       (4500 * (1-PAL)) + (5800 * PAL)       ' time (ns) used in backp calc (NTSC=4.5us, PAL=5.8us)
tfrontp                 =       1500                                  ' time (ns) used in frontp calc (1.5us)
oserr                   =       6        '- (PAL * 1)                 ' no. of equal/serr/equal pulses (NTSC=6, PAL=6 was 5)
oblank0                 =       linesh - (3*oserr/2) - (oscreenrows*8) ' total blank lines  (typ: NTSC=53, PAL=104)
oblank0a                =       (11 * (1-PAL)) + (14 * PAL)           ' no. extra blank lines top (NTSC=11, PAL=14)
oblank1                 =       ((oblank0 - oblank0a) / 2) + oblank0a ' no. of blank lines top (typ: NTSC=32, PAL=58)
oblank2                 =       oblank0 - oblank1                     ' no. of blank lines bot.(typ: NTSC=21, PAL=45)
oactive                 =       oscreenrows * 8                       ' no. of active lines
oequal                  =       osync / 2                             ' VSCL equalization pulse (sync/2)
osynch                  =       ohalf - osync                         ' VSCL half-sync
oequalh                 =       ohalf - oequal                        ' VSCL half-equal
ofrontp                 =       (2*ohalf) -osync -obackp -(oscreencols*8)   ' VSCL front porch (active to sync)
ovsclch                 =       8                                     ' VSCL character (8 PLLA per frame = pixels/char)
omemscreenoffset        =       (otopmargin * omemcols) + oleftmargin ' First visible character is here in the buffer
omemlineoffset          =       (omemcols - oscreencols)              ' Extra characters per line
omemrequired            =       (omemrows * omemcols)                 ' Memory needed for screen buffer
omemreserved            =       omemrequired                          ' Set this to 0 if you allocate screen buffer elsewhere

'--------------------------------------------------------------------------------------------------
'The following are required for all video versions
_xFRQB  =       $4924_0000      ' 40/140 << 32 = 1,227,096,064 (generate PWM for black pixels)
_iCTRB  =       %0_00110_000    ' single ended duty (turn on blank = black)
_iVCFG  =       %0_01_0_0_0_000 ' VGA mode, 1 bit per pixel

VAR
  long  cog
  long  pRENDEZVOUS                                     'buffer to pass characters to 1pinTV driver

PUB start(tvPin, fonttab) | screen                      'pass tv pin#, pointer to mirrorred font data

  ' If you want to use the screen buffer elsewhere, change the following line.
  ' Remember to also change the definition of omemreserved to 0 in the CON section above so that the
  ' Spin compiler doesn't allocate extra space at the end of the DAT section below.
  screen := @entry
  
  pfont := fonttab
    
  stop
  xfrqa := Setforxtalfreq                               'set xfrqa in hub for the current clkfreq before cognew 
  pRENDEZVOUS := screen << 8 | tvPin                   'pass parameters (screen address in hub & pin#)
  cog := COGNEW( @entry,@pRendezvous) + 1
  repeat until pRENDEZVOUS == 0                         'wait until cleared
  result := screen

PUB stop
   COGSTOP( cog~ - 1 )

PRI Setforxtalfreq : f | Freq, PropFreq, shift
'' Return frqa value for the current clkfreq
'' Derived from CTR.SPIN by Chip Gracey

  Freq := ocolsfrq * oscreencols * 8                          'frequency required
  shift := 4 - >|((Freq - 1) / 1_000_000)               'determine shift 
  PropFreq := CLKFREQ

  if shift > 0                                          'if shift, pre-shift Freq or PropFreq left
    Freq <<= shift                                      'to maintain significant bits while
  if shift < 0                                          'insuring proper result
    PropFreq <<= -shift
 
  repeat 32                                             'perform long division of Freq / PropFreq
    f <<= 1
    if Freq => PropFreq
      Freq -= PropFreq
      f++                                               'compute frqa value
    Freq <<= 1

DAT
                        ORG     0
'' +--------------------------------------------------------------------------+
'' | NOTE: The screen buffer will overlay the hub space used by the           |
'' |         following DAT code to save precious space.                       |
'' +--------------------------------------------------------------------------+

entry

'' +--------------------------------------------------------------------------+
'' | 1pin TV Video driver section                                             |
'' +--------------------------------------------------------------------------+

'' The following initialisation code is re-used as variables to conserve valuable cog space...
'' --------------------------------------------------------------------------------------------------
'' i_pin                long    0                       ' pin number
'' i_charptr            long    0                       ' pointer to screen (bytes)
'' char                 long    0                       ' current character / character bitmap
'' charptr              long    0                       ' pointer to current character
'' fontptr              long    0                       ' base address + line offset
'' count                long    0                       ' all purpose counter
'' rownum               long    0                       ' row counter
'' VT100 Terminal variables...
'' ch                   long    0                                                
'' col                  long    0
'' row                  long    0
'' posn                 long    0                       'current cursor posn
'' screenptr            long    0                       'screen hub ptr
'' cursorptr            long    0                       'cursor hub ptr
'' cursorchr            long    0                       'cursor char
'' framectr             long    0                       'frame counter (inc ea frame)
'' taskret              long    0                       'returns to video code

init
i_pin                   nop                             ' Left over from old code, do not remove                                                     

i_charptr               rdlong  i_pin, par              ' input parameters ( @screen << 8 | tvpin )
char                    mov     i_charptr, i_pin
charptr                 and     i_pin, #$FF             ' extract TV pin#
fontptr                 shr     i_charptr, #8           ' extract ptr to hub screen buffer

count                   MOV     FRQB, xfrqb             ' generates PWM for black pixels when required

rownum                  MOVI    CTRA, #ictra            '\set for video clock
ch                      MOV     FRQA, xfrqa             '/

col                     MOVS    CTRB, i_pin             ' set pin
row                     MOV     count, #1
posn                    SHL     count, i_pin
screenptr               MOV     DIRA, count             ' set pin mask
cursorptr               MOV     count, i_pin                               
cursorchr               SHR     count, #3
framectr                MOVD    VCFG, count             ' set VGroup
clscount                MOV     count, #1
taskret                 AND     i_pin, #7                                  
                        SHL     count, i_pin
                        MOVS    VCFG, count             ' set VPins
                        MOVI    VCFG, #_iVCFG           ' VGA mode, 1 bit per pixel

                        mov     framectr, #0

{{ This code can be used to clear the screen on startup; however this makes it impossible to start
   multiple instances of the TV driver because it wipes the code in the hub.
                        mov     screenptr, i_charptr    ' Start at top of video buffer
                        mov     clscount, #omemrequired/4 ' Number of bytes to clear             
:chars                  wrlong  x20202020, screenptr    'clear 4 chars at a time
                        add     screenptr, #4           'inc hub ptr
                        djnz    clscount, #:chars
}}
                        wrlong  framectr, par           ' Let caller know we're ready by setting par[0] to 0 (for future expansion)                        

                        add     i_charptr, #omemscreenoffset ' Add offset to start of buffer
                                                        
'**************************************************************************************************
'Display a frame (1 screen full) non-interlaced B&W
frame                   add     framectr, #1            ' inc frame counter
'--------------------------------------------------------------------------------------------------
                        CALL    #equalizing             ' equalisation pulses (6 sets = 3 lines)
'--------------------------------------------------------------------------------------------------
                        MOVS    pulse1, #xsynch         ' \setup serrations: addr of xsynch
                        MOVS    pulse2, #osync          ' /                  value of osync
                        CALL    #equalizing             ' serration pulses    (6 sets = 3 lines)
                        MOVS    pulse1, #xequal         ' \restore equalizg: addr of xequal
                        MOVS    pulse2, #oequalh        ' /                  value of oequalh
'--------------------------------------------------------------------------------------------------
                        CALL    #equalizing             ' equalisation pulses (6 sets = 3 lines)
'==================================================================================================
                        MOV     rownum, #oblank1
                        CALL    #doblank                ' blank lines (top)
'==================================================================================================
'Display active lines (horiz sync & setup)
                        MOV     rownum, #oactive        ' no. of active visible lines (rows*fontrows)
                        MOV     charptr, i_charptr      ' initialize character pointer
doactive                MOV     VSCL, xsync             ' horiz sync (line)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
                        TEST    rownum, #7      WZ      ' 8 lines per row (new char row?)
        IF_Z            MOV     fontptr, pfont          ' reset fontptr if required (new char row)
        IF_NZ           SUB     charptr, #omemcols      ' reset charptr if required (next pixel row)
        IF_NZ           ADD     fontptr, #1             ' advance to next pixel line
                        MOV     count, #oscreencols     ' characters per line
                        MOVS    VSCL, #obackp           ' back porch (before video pixel line)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #_iCTRB           ' turn on blank
'--------------------------------------------------------------------------------------------------
'Display entire pixel line (screen is in hub, font is in cog)
                        MOVS    VSCL, #ovsclch          ' 8 PLLA per frame (fontcols)
:active                 RDBYTE  char, charptr           ' read character from HUB RAM

                        shl     char, #3
                        add     char, fontptr
:getfont                RDBYTE  char, char
                        add     charptr, #1

                        WAITVID xFFOO, char             ' output 8 pixels to screen
                        DJNZ    count, #:active         ' do entire line
                        add     charptr, #omemlineoffset ' move pointer for skipped buffer characters
'--------------------------------------------------------------------------------------------------
                        MOVS    VSCL, #ofrontp          ' front porch (after video pixel line)
                        WAITVID xFFOO, #0               
                        DJNZ    rownum, #doactive       ' next row
'==================================================================================================
                        mov     rownum, #oblank2
                        call    #doblank                ' blank lines (bottom)
'==================================================================================================
                        JMP     #frame
'**************************************************************************************************

'equalisation and serration pulses
equalizing              MOV     rownum, #oserr          ' =6 pulses
pulse1                  MOV     VSCL, xequal-0          ' equalizing short / serration long
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
pulse2                  MOVS    VSCL, #oequalh-0        ' equalizing long / serration short
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #_iCTRB           ' turn on blank
                        DJNZ    rownum, #pulse1
equalizing_ret          RET
'--------------------------------------------------------------------------------------------------
'do blank lines (top & bottom)
doblank                 MOV     VSCL, xsync             ' horiz sync (line)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
                        MOV     VSCL, xblank            ' line             
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #_iCTRB           ' turn on blank
'                        jmpret  taskret, taskptr        ' to vt100 code
'                        jmpret  taskret, taskptr        ' to vt100 code
                        DJNZ    rownum, #doblank
doblank_ret             RET
'**************************************************************************************************

pfont                   long    0                       ' Font location in hub                 

'--------------------------------------------------------------------------------------------------
'constants > $1FF
xfrqa                   long    0-0                     ' generates pixel clock for videogen (set by spin)
xfrqb                   long    _xFRQB                  ' generates PWM for black pixels
xequal                  long    1<<12 + oequal          ' 1 PLLA per pixel + equalisation time
xsynch                  long    1<<12 + osynch          ' 1 PLLA per pixel + serration time
xsync                   long    1<<12 + osync           ' 1 PLLA per pixel + sync time
xblank                  long    1<<12 + osynch+ohalf    ' 1 PLLA per pixel + blank line (maybe > 9bits so MOVS fails)
xFFOO                   long    $FF00                   ' white / black
x20202020               long    $20202020               ' used for clearing the screen


                        FIT     $1F0

'' +--------------------------------------------------------------------------+
'' | The following fills cog/hub space (if reqd) for larger screens.          |
'' +--------------------------------------------------------------------------+

        long  0[(omemreserved/4 > $) & (omemreserved/4 - $)] 'reserve extra space if screen > cog code


DAT
{{
Original notes from Eric Ball's code...

NOTE: This is not necessarily accurate any more, but is left for information.

This driver was inspired by the Parallax Forum topic "Minimal TV or VGA pins"
http://forums.parallax.com/forums/default.aspx?f=25&m=340731&g=342216
Where Phil Pilgrim provided the following circuit and description of use:
?-?????
    ??
    ??
"White is logic high; sync, logic low; blank level, CTRB programmed for DUTY
 mode with FRQB set to $4924_0000. The advantage of this over tri-stating for
 the blanking level is that the Propeller's video generator can be used to
 generate the visible stuff while CTRB is active. When the video output is high,
 it's ORed with the DUTY output to yield a high; when low, the DUTY-mode value
 takes over. CTRB is simply turned off during the syncs, which has to be handled
 in software.

 The resistor values (124O series, 191O to ground) have an output impedance of
 75 ohms and will drive a 75-ohm load at 1V P-P. The cap is there to filter the
 DUTY doody."

However, in my experience, the RC network is not required. I have tested
successfully using any of the Demoboard TV DAC resistors (although the higher
resistance yields darker text) and with no resistors at all (although this
is not recommended).

Driver limitation details:
CLKFREQ => 12MHz
op_cols =< CLKFRQ / 1.2MHz (LSB) | CLKFREQ / 1.3MHz (MSB)
op_cols * pixels/char => 45
op_pixelclk => 1MHz

Q: Why specify op_pixelclk?
A1: To reduce shimmer caused by the number of significant bits in FRQA.
A2: To allow for WAITVID timing experimentation.
A3: To reduce horizontal overscan & display more characters per line.

Q: Why specify op_blankfrq?
A1: To tune the brightness of the text for a particular display.
A2: To allow for light/dark pulsing text. (Red Alert!!)

Q: Why specify pixels/char <> 8?
A1: To allow for fonts thinner than 8 pixels to be displayed.
A2: To allow for blank pixels between characters (i.e. hexfont.spin)

Q: Why not fonts with vertical sizes <> 8?
A: It probably can be done, but would require a chunk of time-sensitive
   code to be re-written.

Q: Why fewer characters per line for MSB first fonts?  (no longer supported)
A: MSB first fonts require one more instruction in a timing sensitive loop.    

Q: Why is pixels/char embedded in op_mode rather than a separate long?
A1: It's an optional parameter.  op_mode := 1 | 2 will be the norm.
A2: It started as a 1 bit parameter for 9 pixel wide characters, but then
    grew into a nibble.

Technote on video drivers...
Video drivers are constrained by WAITVID to WAITVID timing.  In the inner
active display loop (e.g. :active / :evitca), this determines the maximum
resolution at a given clock frequency.  Other WAITVID to WAITVID intervals
(e.g. front porch) determine the minimum clock frequency.
    
}}

{{
+------------------------------------------------------------------------------------------------------------------------------+
|                                    TERMS OF USE: Parallax Object Exchange License                                            |                                                            
+------------------------------------------------------------------------------------------------------------------------------|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    | 
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
+------------------------------------------------------------------------------------------------------------------------------+
}}