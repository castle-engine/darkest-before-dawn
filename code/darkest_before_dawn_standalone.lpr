{
  Copyright 2013-2014 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{$apptype GUI}

{ Main program for a standalone version of the game.
  This allows you to compile the same game game (in Game unit)
  as a normal, standalone executable for normal OSes (Linux, Windows, MacOSX...). }
program darkest_before_dawn_standalone;

{$ifdef MSWINDOWS}
  {$R ../automatic-windows-resources.res}
{$endif MSWINDOWS}

uses CastleWindow, CastleConfig, Game;
begin
  Window.FullScreen := true;
  Window.ParseParameters;

  Config.Load;
  Application.Initialize;
  Window.OpenAndRun;
  Config.Save;
end.
