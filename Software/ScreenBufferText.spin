''***************************************************************************
''* ScreenBufferText
''* Copyright (C) 2013 Jac Goudsmit
''*
''* TERMS OF USE: MIT License. See bottom of file.                                                            
''***************************************************************************
''
'' This module implements a universal text API for spin, that writes
'' characters into a screen buffer in hub memory. This makes it possible to
'' use a TV or VGA driver without text interface, and use this module to
'' generate text on it.
''
'' It allows the definition of a viewport, so that it doesn't use the entire
'' screen. That way, it's possible to declare multiple instances of this
'' module in an OBJ section, and let each of them write to multiple areas of
'' the screen, or to share the screen with other modules that use the entire
'' screen. There are functions to save and restore the viewport to help with
'' this. Obviously if other code uses the entire screen, it should somehow
'' be aware of the sharing, so that the buffer is only used by one piece of
'' code at a time.  
''
'' The module uses no cog and if it's used for debugging only, it can be
'' removed from the final product without modifying the screen driver. Keep
'' in mind that for simple text copying, you don't need this module: you
'' can always use BYTEMOVE and STRSIZE, and to clear the screen you can use
'' BYTEFILL.

CON
  ' Carriage return modes for Chr / Str / CR / LF functions
  #0
  CRLF_CR_LF                    ' CR=Carriage Return, LF=line feed
  CRLF_CRLF_LF                  ' CR=Carriage Return Line Feed, LF=line feed
  CRLF_CR_CRLF                  ' CR=Carriage Return, LF=Carriage Return Line Feed
  CRLF_CRLF_CRLF                ' CR=LF=Carriage Return Line Feed
                            
VAR

  ' Pointers into hub memory
  long  buf
  long  view
  
  ' Buffer info
  word  bufcols
  word  bufrows

  ' Viewport info
  word  viewcols
  word  viewrows
  word  viewleft
  word  viewtop

  ' CR/LF behavior
  byte crdoeslf
  byte lfdoescr
  
  ' Cursor
  long  row ' relative to view; must be long because it can become temporarily negative
  long  col ' relative to view; must be long because it can become temporarily negative

  ' Other
  byte  decbuf[11]

PUB Start(parm_buf, parm_bufcols, parm_bufrows, parm_viewcols, parm_viewrows, parm_viewleft, parm_viewtop, parm_crlf)
'' Initialize the module
''
'' parm_buf      = pointer to screen buffer (one byte per character)
'' parm_bufcols  = number of characters per row in screen buffer
'' parm_bufrows  = number of character rows in screen buffer
'' parm_viewcols = number of characters per row in view port (max=parm_bufcols - parm_viewleft)  
'' parm_viewrows = number of rows in view port (max=parm_bufrows - parm_viewtop) 
'' parm_viewleft = number of columns in memory to skip (max=parm_bufcols - 1)
'' parm_viewtop  = number of rows in memory to skip (max=parm_bufrows - 1)
'' parm_crlf     = carriage return mode, see constants
''
'' The routine doesn't check whether the values are in range. 

  buf      := parm_buf
  bufcols  := parm_bufcols
  bufrows  := parm_bufrows
  viewcols := parm_viewcols  
  viewrows := parm_viewrows 
  viewleft := parm_viewleft
  viewtop  := parm_viewtop

  crdoeslf := (parm_crlf == CRLF_CRLF_LF) or (parm_crlf == CRLF_CRLF_CRLF)
  lfdoescr := (parm_crlf == CRLF_CR_CRLF) or (parm_crlf == CRLF_CRLF_CRLF)

  view  := buf + viewtop * bufcols + viewleft
      
  cls  

PUB StartScreen(parm_buf, parm_cols, parm_rows, parm_crlf)
'' Initialize the module; the viewport is set to cover the entire screen
''
'' parm_buf      = pointer to screen buffer (one byte per character)
'' parm_cols     = number of characters per row in screen buffer
'' parm_rows     = number of character rows in screen buffer
'' parm_crlf     = carriage return mode, see constants
''
'' The routine doesn't check whether the values are in range.

  Start(parm_buf, parm_cols, parm_rows, parm_cols, parm_rows, 0, 0, parm_crlf) 

PUB GetLinePtr(viewrow)
'' Get the pointer to a row of characters in the view

  result := view + viewrow * bufcols

PUB GetPtr(viewrow, viewcol)
'' Get the pointer to a character in the buffer based on view coordinates

  result := GetLinePtr(viewrow) + viewcol

PUB GetCursorPtr
'' Get the pointer to the current cursor location on the screen

  result := GetPtr(row, col)
  
PUB GetViewSize
'' Get size of the view in bytes, needed to copy it

  result := viewrows * viewcols

PUB SaveView(dest) | i
'' Copy the current view to the given destination pointer as one block of memory

  repeat i from 0 to viewrows
    bytemove(dest + i * viewcols, GetLinePtr(i), viewcols)

PUB LoadView(src) | i
'' Copy the given buffer to the current view as one block of memory

  repeat i from 0 to viewrows
    bytemove(GetLinePtr(i), src + i * viewcols, viewcols)
             
PUB Cls | i
'' Clear the view

  repeat i from 0 to viewrows - 1
    bytefill(GetLinePtr(i), $20, viewcols)
    
  Home

PUB Home
'' Send the cursor to the home location

  row := 0
  col := 0

PUB ScrollUp(numrows) | i
'' Scroll the view up (adding blank lines at the bottom) and
'' move the cursor with the scrolling text

  if numrows => viewrows
    cls
    row := 0
  else  
    repeat i from numrows to viewrows - 1
      bytemove(GetLinePtr(i - numrows), GetLinePtr(i), viewcols)
    repeat i from viewrows - numrows to viewrows - 1
      bytefill(GetLinePtr(i), $20, viewcols)
    row -= numrows    

PUB ScrollDown(numrows) | i
'' Scroll the view down (adding blank lines at the top) and
'' move the cursor with the scrolling text

  if numrows => viewrows
    cls
    row := viewrows - 1
  else
    repeat i from viewrows - 1 to numrows
      bytemove(GetLinePtr(i), GetLinePtr(i - numrows), viewcols)
    repeat i from 0 to numrows - 1
      bytefill(GetLinePtr(i), $20, viewcols)
    row += numrows

PRI UpdateCursor
' Checks whether the cursor and row columns are in the view
' If not, goes to the next line
' If next line is beyond bottom of view, scroll the view up

  if col < 0
    col := viewcols - 1
    row--

  if row < 0
    ScrollDown(-row)    
    
  if col => viewcols
    col := 0
    row++

  if row => viewrows
    ScrollUp(row - viewrows) ' This also updates the cursor pointer

PUB GoToXY(parm_col, parm_row)
'' Send the cursor to the given row and column within the view
'' If the parameters are out of range, the cursor will go to the
'' start of the next line behind the requested coordinates,
'' and will scroll the screen if necessary

  row := parm_row
  col := parm_col

  UpdateCursor

PUB GetX
'' Get the current cursor column

  result := col

PUB GetY
'' Get the current cursor row

  result := row

PRI RealCR
' Performs Carriage Return regardless of mode

  col := 0

PRI RealLF
' Performs Line Feed regardless of mode

  row++
  UpdateCursor

PUB CRLF
'' Performs Carriage Return Line Feed regardless of mode

  col := 0
  row++
  UpdateCursor
    
PUB CR
'' Performs Carriage Return according to mode

  if crdoeslf
    CRLF
  else
    RealCR

PUB LF
'' Performs Line Feed according to mode

  if lfdoescr
    CRLF
  else
    RealLF

PUB RawChr(c)
'' Put a raw character at the cursor location and update the location
'' This is faster than the next method

  byte[GetPtr(row, col)] := c
  col++
  UpdateCursor
      
PUB Chr(c)
'' Print a character or execute special code
''
'' Special codes are:
'' $00 =  0 = clear viewport
'' $08 =  8 = cursor left
'' $09 =  9 = tab (advance to next column that is a multiple of 8)
'' $0A = 10 = line feed (see constants)
'' $0B = 11 = home (vertical tab)
'' $0C = 12 = clear viewport (form feed)
'' $0D = 13 = carriage return (see constants)
'' $1C = 28 = cursor right
'' $1D = 29 = cursor left
'' $1E = 30 = cursor up
'' $1F = 31 = cursor down
'' others   = show character at cursor location, advance cursor

  ' Don't do the costly "case" if we know the character is printable, not special
  if c > 32
    RawChr(c)
  else
    case c
     
      ' Clear viewport
      $00, $0C:
        Cls
     
      ' Tab
      $09:
        repeat
          Chr($20)
        while col & 7
     
      ' Line feed
      $0A:
        LF
     
      ' Home
      $0B:
        Home
        
      ' Carriage Return
      $0D:
        CR
     
      ' Cursor Right
      $1C:
        col++
        UpdateCursor
     
      ' Cursor Left
      $1D, $08:
        col--
        UpdateCursor
     
      ' Cursor Up
      $1E:
        row--
        UpdateCursor
     
      ' Cursor Down
      $1F:
        row++
        UpdateCursor
      
      other:
        RawChr(c)
     
PUB Str(s) | c
'' Print a zero-terminate string and handle any embedded command characters
'' This is not as efficient as below but handles special command characters

  repeat
    c := byte[s++]
    if c == 0
      quit
    Chr(c)

PUB Text(s) | len
'' Print a zero-terminated string
'' This is more efficient than above but doesn't handle special command characters

  repeat
    len := strsize(s) <# (viewcols - col)
    if len
      bytemove(GetPtr(row, col), s, len)
      col += len
      UpdateCursor
      s += len
    else
      quit

PUB Dec(value) | i
'' Print a decimal number

  if value < 0
    -value
    RawChr("-")

  i := 10
  decbuf[i] := 0
  repeat
    decbuf[--i] := (value // 10) + "0"
    value /= 10
  until value == 0

  Text(@decbuf + i)

PUB Hex(value, digits)
'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    RawChr(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB Bin(value, digits)
'' Print a binary number

  value <<= 32 - digits
  repeat digits
    RawChr((value <-= 1) & 1 + "0")

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
                   