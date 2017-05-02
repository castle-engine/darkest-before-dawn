{
  Copyright 2013-2017 Michalis Kamburelis, Jan Adamec.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Library to run the game on iOS. }
{$mode objfpc}{$H+}

uses Game, CastleWindow;

exports
  CGEApp_Open,
  CGEApp_Close,
  CGEApp_Render,
  CGEApp_Resize,
  CGEApp_SetLibraryCallbackProc,
  CGEApp_Update,
  CGEApp_MouseDown,
  CGEApp_Motion,
  CGEApp_MouseUp,
  CGEApp_KeyDown,
  CGEApp_KeyUp,
  CGEApp_SetDpi;

begin
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
    exOverflow, exUnderflow, exPrecision]);
end.
