{
  Copyright 2013-2016 Michalis Kamburelis.

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

uses CastleWindowTouch, CastlePlayer, CastleLevels, CastleCreatures;

var
  Window: TCastleWindowTouch;

procedure Start(AOptions: boolean);

implementation

uses SysUtils, CastleLog, CastleWindow, CastleProgress, CastleWindowProgress,
  CastleControls, CastlePrecalculatedAnimation, CastleGLImages, CastleConfig,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils,
  GameOptions, GamePlay, GameGooglePlayGames, GameAds;

{ routines ------------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  InitializeLog;

  GooglePlayGames.Initialize;
  AdInitialize;

  Progress.UserInterface := WindowProgressInterface;

  { adjust theme }
  Theme.Images[tiProgressFill] := LoadImage(ApplicationData('ui/theme/ProgressFill.png'));
  Theme.OwnsImages[tiProgressFill] := true;
  Theme.Images[tiButtonPressed] := LoadImage(ApplicationData('ui/theme/ButtonPressed.png'));
  Theme.OwnsImages[tiButtonPressed] := true;
  Theme.Images[tiButtonFocused] := LoadImage(ApplicationData('ui/theme/ButtonFocused.png'));
  Theme.OwnsImages[tiButtonFocused] := true;
  Theme.Images[tiButtonNormal] := LoadImage(ApplicationData('ui/theme/ButtonNormal.png'));
  Theme.OwnsImages[tiButtonNormal] := true;

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

procedure ApplicationTimer;
begin
  WritelnLog('FPS', '%f (real : %f)',
    [Window.Fps.FrameTime, Window.Fps.RealTime]);
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
  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png')) else
  if Event.IsKey(K_F8) then
  begin
    { test whether close+open of context works Ok. }
    Window.Close(false);
    Window.Open;
  end;
  if Event.IsKey(K_Escape) then
    Application.Terminate;
end;

function MyGetApplicationName: string;
begin
  Result := 'darkest_before_dawn';
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;
  Application.OnTimer := @ApplicationTimer;
  Application.TimerMilisec := 5000;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowTouch.Create(Application);
  Application.MainWindow := Window;
  Window.OnResize := @WindowResize;
  Window.OnUpdate := @WindowUpdate;
  Window.OnPress := @WindowPress;
end.
