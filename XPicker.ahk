#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance, Force

; Setup
OnExit, Exit
xcolorIcon := A_ScriptFullPath

; Hotkeys
Hotkey, RButton, CatchColor ; HEX (Default)
Hotkey, ^RButton, CatchColor ; RGB
Hotkey, Esc, Exit  ; Assigning Esc key to Exit subroutine

; Initiation
Traytip, XPicker:, RIGHTCLICK to copy HEX value`nAdd CTRL for RGB value, 5
SetSystemCursor("IDC_CROSS") ; Set the cursor to IDC_CROSS
RestoreCursorsOnExit := true ; Flag to restore cursors on exit

; MAIN LOOP: Pick Color
Loop
{
    CoordMode, Mouse, Screen
    MouseGetPos, X, Y
    PixelGetColor, Color, X, Y, RGB
    Color := "0x" . SubStr(Color, 3) ; Ensure color is in correct format

    ; Show color in GUI
    if GetKeyState("LControl")
        ColorMessage := HexToRGB(Color, "Message")
    else
        ColorMessage := "#" . SubStr(Color, 3)  ; Prepend # to HEX color

    Gui, xcolor:Color, % Color
    Tooltip, % ColorMessage
    CoordMode, Pixel 
    mX := X - 30 ; Offset Tooltip from Mouse
    mY := Y - 80
    Gui, xcolor:-Caption +ToolWindow +LastFound +AlwaysOnTop +Border
    Gui, xcolor:Show, NoActivate x%mX% y%mY% w60 h60
}

return

CatchColor: ; Catch Hover'd color
if (A_ThisHotkey = "^RButton")
    Out := "RGB"

; Continue processing color
GoSub, ColorPicked
return

ColorPicked:
Color := "0x" . SubStr(Color, 3) ; Ensure color is in correct format

If (Out = "RGB")
{
    OutColor := HexToRGB(Color, "RGB")
    OutMsg := HexToRGB(Color, "Message")
    Clipboard := OutMsg
}
else
{
    OutColor := HexToRGB(Color)
    OutMsg := OutColor
    Clipboard := OutColor
}

Traytip, xcolor:, % OutMsg " picked"
RestoreCursors()
Gui, xcolor:Destroy
Sleep, 500
Hotkey, ^RButton, Off
Hotkey, RButton, Off
Sleep, 1500
GoSub, Exit
return

Exit: ; Exit subroutine
if (RestoreCursorsOnExit)
    RestoreCursors()
ExitApp
return

; FUNCTIONS
HexToRGB(Color, Mode="")
{
    R := SubStr(Color, 3, 2)
    G := SubStr(Color, 5, 2)
    B := SubStr(Color, 7, 2)

    if (Mode = "Message")
        return "R: " . R . ", G: " . G . ", B: " . B
    else if (Mode = "RGB")
        return R . "," . G . "," . B
    else
        return "#" . SubStr(Color, 3)  ; Keep "#" for HTML color codes
}

RestoreCursors()
{
    SPI_SETCURSORS := 0x57
    DllCall("SystemParametersInfo", UInt, SPI_SETCURSORS, UInt, 0, UInt, 0, UInt, 0)
}

SetSystemCursor( Cursor = "", cx = 0, cy = 0 )
{
   BlankCursor := 0, SystemCursor := 0, FileCursor := 0 ; init
   
   SystemCursors = 32512IDC_ARROW,32513IDC_IBEAM,32514IDC_WAIT,32515IDC_CROSS
   ,32516IDC_UPARROW,32640IDC_SIZE,32641IDC_ICON,32642IDC_SIZENWSE
   ,32643IDC_SIZENESW,32644IDC_SIZEWE,32645IDC_SIZENS,32646IDC_SIZEALL
   ,32648IDC_NO,32649IDC_HAND,32650IDC_APPSTARTING,32651IDC_HELP
   
   If Cursor = ; empty, so create blank cursor 
   {
      VarSetCapacity( AndMask, 32*4, 0xFF ), VarSetCapacity( XorMask, 32*4, 0 )
      BlankCursor = 1 ; flag for later
   }
   Else If SubStr( Cursor,1,4 ) = "IDC_" ; load system cursor
   {
      Loop, Parse, SystemCursors, `,
      {
         CursorName := SubStr( A_Loopfield, 6, 15 ) ; get the cursor name, no trailing space with substr
         CursorID := SubStr( A_Loopfield, 1, 5 ) ; get the cursor id
         SystemCursor = 1
         If ( CursorName = Cursor )
         {
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )   
            Break               
         }
      }   
      If CursorHandle = ; invalid cursor name given
      {
         Msgbox,, SetCursor, Error: Invalid cursor name
         CursorHandle = Error
      }
   }   
   Else If FileExist( Cursor )
   {
      SplitPath, Cursor,,, Ext ; auto-detect type
      If Ext = ico 
         uType := 0x1   
      Else If Ext in cur,ani
         uType := 0x2      
      Else ; invalid file ext
      {
         Msgbox,, SetCursor, Error: Invalid file type
         CursorHandle = Error
      }      
      FileCursor = 1
   }
   Else
   {   
      Msgbox,, SetCursor, Error: Invalid file path or cursor name
      CursorHandle = Error ; raise for later
   }
   If CursorHandle != Error 
   {
      Loop, Parse, SystemCursors, `,
      {
         If BlankCursor = 1 
         {
            Type = BlankCursor
            %Type%%A_Index% := DllCall( "CreateCursor"
            , Uint,0, Int,0, Int,0, Int,32, Int,32, Uint,&AndMask, Uint,&XorMask )
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }         
         Else If SystemCursor = 1
         {
            Type = SystemCursor
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )   
            %Type%%A_Index% := DllCall( "CopyImage"
            , Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )      
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }
         Else If FileCursor = 1
         {
            Type = FileCursor
            %Type%%A_Index% := DllCall( "LoadImageA"
            , UInt,0, Str,Cursor, UInt,uType, Int,cx, Int,cy, UInt,0x10 ) 
            DllCall( "SetSystemCursor", Uint,%Type%%A_Index%, Int,SubStr( A_Loopfield, 1, 5 ) )         
         }          
      }
   }   
}
