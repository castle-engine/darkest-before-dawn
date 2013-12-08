{
  Copyright 2013 Michalis Kamburelis.

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
  CastleControls, CastlePrecalculatedAnimation, CastleGLImages,
  CastleImages, CastleFilesUtils,
  GameOptions, GamePlay;

{ routines ------------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  {$ifndef MSWINDOWS} { Under Windows, log requires stderr. }
  InitializeLog;
  {$endif}

  { adjust theme }
  Theme.Images[tiProgressFill] := LoadImage(ApplicationData('ui/progress_fill.png'));
  Theme.OwnsImages[tiProgressFill] := true;

  { create 2D and 3D stuff for game and for options screen }
  PlayInitialize(Window);
  OptionsInitialize(Window);
end;

procedure ApplicationTimer;
begin
  WritelnLog('FPS', '%f (real : %f)',
    [Window.Fps.FrameTime, Window.Fps.RealTime]);
end;

procedure WindowOpen(Sender: TCastleWindowBase);
begin
  { show progress bars on our Window }
  Progress.UserInterface := WindowProgressInterface;
  WindowProgressInterface.Window := Window;
  Start(true);
end;

procedure WindowClose(Sender: TCastleWindowBase);
begin
  Progress.UserInterface := ProgressNullInterface;
end;

procedure WindowResize(Sender: TCastleWindowBase);
begin
  PlayResize(Window);
  OptionsResize(Window);
end;

procedure WindowUpdate(Sender: TCastleWindowBase);
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
    WindowUpdate(Window);
  end else
  begin
    { update Exists for Options controls. Do not touch Play controls yet,
      they are not prepared to be updated before GameStart, when Player
      may not exist. }
    OptionsUpdate(Window);
    GameStart;
  end;
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
  Window.OnOpen := @WindowOpen;
  Window.OnClose := @WindowClose;
  Window.OnResize := @WindowResize;
  Window.OnUpdate := @WindowUpdate;
end.