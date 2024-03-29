{
  Copyright 2013-2022 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindow, CastleViewport, CastleLevels;

var
  Window: TCastleWindow;
  TouchNavigation: TCastleTouchNavigation;

procedure Start(AOptions: boolean);

implementation

uses SysUtils, CastleLog, CastleProgress, CastleWindowProgress,
  CastleControls, CastleGLImages, CastleConfig, CastleApplicationProperties,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils, CastleTransform,
  CastleUIControls, CastlePlayer, CastleCreatures,
  GameOptions, GamePlay, GameGooglePlayGames, GameAds;

{ routines ------------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  SceneManager := TGameSceneManager.Create(Application);
  SceneManager.FullSize := true;
  Window.Controls.InsertFront(SceneManager);

  TouchNavigation := TCastleTouchNavigation.Create(Application);
  // TouchNavigation.AutoTouchInterface := true; // leave false, GamePlay adjusts TouchNavigation.TouchInterface
  TouchNavigation.Viewport := SceneManager;
  TouchNavigation.FullSize := true;
  SceneManager.InsertFront(TouchNavigation);

  TCastleTransform.DefaultOrientation := otUpYDirectionMinusZ; // suitable for old kanim animations with X3D

  InitializeLog;

  GooglePlayGames.Initialize;
  AdInitialize;

  Progress.UserInterface := WindowProgressInterface;

  { adjust theme }
  Theme.ImagesPersistent[tiProgressFill].Url := 'castle-data:/ui/theme/ProgressFill.png';
  Theme.ImagesPersistent[tiButtonPressed].Url := 'castle-data:/ui/theme/ButtonPressed.png';
  Theme.ImagesPersistent[tiButtonFocused].Url := 'castle-data:/ui/theme/ButtonFocused.png';
  Theme.ImagesPersistent[tiButtonNormal].Url := 'castle-data:/ui/theme/ButtonNormal.png';

  UserConfig.Load;

  Quality := TQuality(Clamped(
    UserConfig.GetValue('quality', Ord(DefaultQuality)), 0, Ord(High(TQuality))));
  Gamma := TGamma(Clamped(
    UserConfig.GetValue('gamma', Ord(DefaultGamma)), 0, Ord(High(TGamma))));

  { create 2D and 3D stuff for game and for options screen }
  PlayInitialize(Window);
  OptionsInitialize(Window);

  Start(true);
end;

procedure WindowResize(Container: TUIContainer);
begin
  PlayResize(Window);
  OptionsResize(Window);
end;

procedure WindowUpdate(Container: TUIContainer);
begin
  PlayUpdate(Window);
  OptionsUpdate(Window);
end;

procedure Start(AOptions: boolean);
begin
  Options := AOptions;
  if Options then
  begin
    { update Exists for all controls }
    WindowUpdate(Window.Container);
  end else
  begin
    { update Exists for Options controls. Do not touch Play controls yet,
      they are not prepared to be updated before GameStart, when Player
      may not exist. }
    OptionsUpdate(Window);
    GameStart;
  end;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.IsKey(keyF5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png')) else
  if Event.IsKey(keyF8) then
  begin
    { test whether close+open of context works Ok. }
    Window.Close(false);
    Window.Open;
  end;
  if Event.IsKey(keyEscape) then
    Application.Terminate;
end;

initialization
  { Set ApplicationName early, as our log uses it.
    Optionally you could also set ApplicationProperties.Version here. }
  ApplicationProperties.ApplicationName := 'darkest_before_dawn';

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindow.Create(Application);
  Application.MainWindow := Window;
  Window.OnResize := @WindowResize;
  Window.OnUpdate := @WindowUpdate;
  Window.OnPress := @WindowPress;
end.
