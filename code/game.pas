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
  SceneManager: TGameSceneManager; //< same thing as Window.SceneManager
  Player: TPlayer; //< same thing as Window.SceneManager.Player
  ResourceHarpy: TWalkAttackCreatureResource;
  GameWin: boolean;
  GoingUp: boolean; // set by level logic

implementation

uses SysUtils, CastleWindow, CastleControls, CastleUIControls, CastleVectors,
  CastleColors, CastleFilesUtils, CastleLog, CastleSceneCore, CastleImages,
  CastleResources, CastleGLUtils, CastleUtils, CastleRectangles, CastleCameras,
  CastleSceneManager, CastleProgress, CastleWindowProgress,
  GameLevels { use, to run GameLevels initialization, to register level logic };

procedure GameRestart; forward;

var
  GoingUpImage: TCastleImageControl;

{ TGame2DControls ------------------------------------------------------------ }

const
  UIMargin = 10;

type
  TGame2DControls = class(TUIControl)
  public
    procedure Draw; override;
    function DrawStyle: TUIControlDrawStyle; override;
  end;

function TGame2DControls.DrawStyle: TUIControlDrawStyle;
begin
  Result := ds2D;
end;

procedure TGame2DControls.Draw;
var
  R: TRectangle;
begin
  if Player.Dead then
    GLFadeRectangle(ContainerRect, Red, 1.0) else
    GLFadeRectangle(ContainerRect, Player.FadeOutColor, Player.FadeOutIntensity);

  R := Rectangle(UIMargin, UIMargin, 40, 100);
  DrawRectangle(R.Grow(2), Vector4Single(1.0, 0.5, 0.5, 0.2));
  if not Player.Dead then
  begin
    R.Height := Clamped(Round(
      MapRange(Player.Life, 0, Player.MaxLife, 0, R.Height)), 0, R.Height);
    DrawRectangle(R, Vector4Single(1, 0, 0, 0.9));
  end;
end;

var
  Game2DControls: TGame2DControls;

{ restart button ------------------------------------------------------------- }

type
  TRestartButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

procedure TRestartButton.DoClick;
begin
  { simple method, to test whether close+open of context works Ok.
  Window.Close(false);
  Window.Open; }
  GameRestart;
end;

var
  RestartButton: TRestartButton;

{ quick creature optimization ------------------------------------------------ }

type
  TGame = class
    function CreatureExists(const Creature: TCreature): boolean;
  end;

function TGame.CreatureExists(const Creature: TCreature): boolean;
const
  DistanceToActivateCreatures = 100.0;
begin
  Result := PointsDistanceSqr(Creature.Position, Player.Position) <=
    Sqr(DistanceToActivateCreatures);
end;

{ routines ------------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  {$ifndef MSWINDOWS} { Under Windows, log requires stderr. }
  InitializeLog;
  {$endif}

  SceneManager := Window.SceneManager;

  //Resources.LoadFromFiles; // cannot search recursively in Android assets
  Resources.AddFromFile(ApplicationData('creatures/light/resource.xml'));
  ResourceHarpy := Resources.FindName('Harpy') as TWalkAttackCreatureResource;

  //Levels.LoadFromFiles; // cannot search recursively in Android assets
  Levels.AddFromFile(ApplicationData('level/1/level.xml'));

  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := '';
  RestartButton.Image := LoadImage(ApplicationData('ui/restart.png'), []);
  RestartButton.OwnsImage := true;
  Window.Controls.InsertFront(RestartButton);

  Game2DControls := TGame2DControls.Create(Application);
  Window.Controls.InsertFront(Game2DControls);

  GoingUpImage := TCastleImageControl.Create(Application);
  GoingUpImage.URL := ApplicationData('ui/going_up.png');
  Window.Controls.InsertFront(GoingUpImage);

  Theme.Images[tiProgressFill] := LoadImage(ApplicationData('ui/progress_fill.png'), []);
  Theme.OwnsImages[tiProgressFill] := true;

  { Disable some default input shortcuts defined by CastleSceneManager.
    They will not do anything if we don't use the related functionality
    (if we don't put anything into the default Player.Inventory),
    but it's a little cleaner to still disable them to avoid spurious
    warnings like "No weapon equipped" on each each press on Ctrl key. }
  Input_Attack.MakeClear;
  Input_InventoryShow.MakeClear;
  Input_InventoryPrevious.MakeClear;
  Input_InventoryNext.MakeClear;
  Input_UseItem.MakeClear;
  Input_DropItem.MakeClear;
  Input_CancelFlying.MakeClear;

  OnCreatureExists := @TGame(nil).CreatureExists;
end;

{ One-time initialization. }
procedure ApplicationTimer;
begin
  WritelnLog('FPS', '%f (real : %f)',
    [Window.Fps.FrameTime, Window.Fps.RealTime]);
end;

const
  AliveTouchInterface = etciCtlWalkDragRotate;
    { etciNone;
      For this game, etciNone is too troublesome, as you often mistakenly
      do walk/rotate when you want to do only the other thing.
      It's important here, as accidental movement moves you away from light,
      which has (deadly) gameplay consequences :) }

procedure GameRestart;
var
  Walk: TWalkCamera;
begin
  GameWin := false;

  if Player <> nil then
    FreeAndNil(Player); // SceneManager references will be cleared automatically
  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  SceneManager.LoadLevel('1');

  { just for test, load 3D model without the CastleLevels stuff }
  // Window.Load(ApplicationData('level/1/level1_final.x3dv'));
  // Window.MainScene.Spatial := [ssRendering, ssDynamicCollisions];
  // Window.MainScene.ProcessEvents := true;

  Window.TouchInterface := AliveTouchInterface;

  { SceneManager.LoadLevel always initializes Camera, always to TWalkCamera }
  Walk := SceneManager.Camera as TWalkCamera;
  Walk.MouseDraggingHorizontalRotationSpeed := 0.5;
  Walk.MouseDraggingVerticalRotationSpeed := 0;
  Player.EnableCameraDragging := true;
end;

procedure WindowOpen(Sender: TCastleWindowBase);
begin
  { show progress bars on our Window }
  Progress.UserInterface := WindowProgressInterface;
  WindowProgressInterface.Window := Window;

  GameRestart;
end;

procedure WindowClose(Sender: TCastleWindowBase);
begin
  Progress.UserInterface := ProgressNullInterface;
end;

procedure WindowResize(Sender: TCastleWindowBase);
begin
  RestartButton.Left := (Window.Width - RestartButton.Width) div 2;
  RestartButton.Bottom := (Window.Height - RestartButton.Height) div 2;

  GoingUpImage.Left := (Window.Width - GoingUpImage.Width) div 2;
  GoingUpImage.Bottom := (Window.Height - GoingUpImage.Height) div 2;
end;

procedure WindowUpdate(Sender: TCastleWindowBase);
const
  RegenerateSpeed = 1.8; // life points per second you gain
begin
  RestartButton.Exists := Player.Dead or GameWin;

  GoingUpImage.Exists := (not RestartButton.Exists) and GoingUp;
  { Reset GoingUp every frame. If we're still GoingUp, it will be set again
    to true before next check above. }
  GoingUp := false;

  if not Player.Dead then
  begin
    Window.TouchInterface := AliveTouchInterface;
    Player.Life := Min(Player.MaxLife,
      Player.Life + Window.Fps.UpdateSecondsPassed * RegenerateSpeed);
  end else
    Window.TouchInterface := etciNone;
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