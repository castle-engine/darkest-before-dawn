{
  Copyright 2013-2025 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Initialize the game. }
unit Game;

interface

implementation

uses SysUtils,
  CastleWindow, CastleViewport, CastleLog,
  CastleControls, CastleGLImages, CastleConfig, CastleApplicationProperties,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils, CastleTransform,
  CastleUIControls,
  GameOptions, GamePlay, GameGooglePlayGames;

var
  Window: TCastleWindow;

{ routines ------------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  TCastleTransform.DefaultOrientation := otUpYDirectionMinusZ; // suitable for old kanim animations with X3D

  GooglePlayGames.Initialize;

  { adjust theme }
  Theme.ImagesPersistent[tiButtonPressed].Url := 'castle-data:/ui/theme/ButtonPressed.png';
  Theme.ImagesPersistent[tiButtonFocused].Url := 'castle-data:/ui/theme/ButtonFocused.png';
  Theme.ImagesPersistent[tiButtonNormal].Url := 'castle-data:/ui/theme/ButtonNormal.png';

  UserConfig.Load;

  Quality := TQuality(Clamped(
    UserConfig.GetValue('quality', Ord(DefaultQuality)), 0, Ord(High(TQuality))));
  Gamma := TGamma(Clamped(
    UserConfig.GetValue('gamma', Ord(DefaultGamma)), 0, Ord(High(TGamma))));

  ViewPlay := TViewPlay.Create(Application);
  ViewOptions := TViewOptions.Create(Application);
  Window.Container.View := ViewOptions;
end;

initialization
  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindow.Create(Application);
  Application.MainWindow := Window;
end.
