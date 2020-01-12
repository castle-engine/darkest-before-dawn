{
  Copyright 2013-2017 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game playing logic (as opposed to logic in the options menu). }
unit GamePlay;

{ Should we use touch interface.
  Note: do *not* base this on OpenGLES define, as
  1. final programs should not include castleconf.inc file,
  2. generally OpenGLES usage is not related to whether platform uses
     touch input (it only so happens that *right now*, by default,
     only Android and iOS use OpenGLES and only they have touch input).
     Making it orthogonal allows to e.g. test TOUCH_INTERFACE with normal
     desktop OpenGL rendering. }
{ $define TOUCH_INTERFACE} // useful to test TOUCH_INTERFACE on desktops
{$ifdef ANDROID} {$define TOUCH_INTERFACE} {$endif}
{$ifdef iOS}     {$define TOUCH_INTERFACE} {$endif}

interface

uses CastleWindow, CastlePlayer, CastleLevels, CastleCreatures,
  CastleWindowTouch;

var
  SceneManager: TGameSceneManager; //< same thing as Window.SceneManager
  Player: TPlayer; //< same thing as Window.SceneManager.Player
  ResourceHarpy: TWalkAttackCreatureResource;
  GameWin: boolean;
  GoingUp: boolean; // set by level logic

procedure PlayInitialize(Window: TCastleWindowTouch);

{ Called every frame. Do continous game logic, e.g. do regeneration.
  Update Exists state of our GUI, based on GameOptions.Options value. }
procedure PlayUpdate(Window: TCastleWindowTouch);

{ Resize GUI to current window size. }
procedure PlayResize(Window: TCastleWindowTouch);

procedure GameStart;

implementation

uses SysUtils, Math,
  CastleControls, CastleUIControls, CastleVectors,
  CastleColors, CastleFilesUtils, CastleLog, CastleSceneCore, CastleImages,
  CastleResources, CastleGLUtils, CastleUtils, CastleRectangles, CastleCameras,
  CastleSceneManager, X3DLoad, CastleGLImages, GameOptions,
  Game, GameAds,
  GameLevels { use, to run GameLevels initialization, to register level logic };

var
  GoingUpImage: TCastleImageControl;

{ TGame2DControls ------------------------------------------------------------ }

const
  UIMargin = 10;

type
  TGame2DControls = class(TCastleUserInterface)
  public
    procedure Render; override;
  end;

procedure TGame2DControls.Render;
var
  R: TRectangle;
begin
  if Player.Dead then
    GLFadeRectangleDark(ParentRect, Red, 1.0)
  else
    GLFadeRectangleDark(ParentRect, Player.FadeOutColor, Player.FadeOutIntensity);

  R := Rectangle(UIMargin, UIMargin, 40, 100);
  DrawRectangle(R.Grow(2), Vector4(1.0, 0.5, 0.5, 0.2));
  if not Player.Dead then
  begin
    R.Height := Clamped(Round(
      MapRange(Player.Life, 0, Player.MaxLife, 0, R.Height)), 0, R.Height);
    DrawRectangle(R, Vector4(1, 0, 0, 0.9));
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
const
  AdChance = 0.5;
begin
  Start(true);
  if Random < AdChance then
    AdShowFullScreen;
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
  Result := PointsDistanceSqr(Creature.Translation, Player.Translation) <=
    Sqr(DistanceToActivateCreatures);
end;

{ Play globals --------------------------------------------------------------- }

procedure PlayInitialize(Window: TCastleWindowTouch);
begin
  SceneManager := Window.SceneManager;

  //Resources.LoadFromFiles; // cannot search recursively in Android assets
  Resources.AddFromFile('castle-data:/creatures/light/resource.xml');
  ResourceHarpy := Resources.FindName('Harpy') as TWalkAttackCreatureResource;

  //Levels.LoadFromFiles; // cannot search recursively in Android assets
  Levels.AddFromFile('castle-data:/level/1/level.xml');

  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := '';
  RestartButton.Image.URL := 'castle-data:/ui/restart.png';
  Window.Controls.InsertFront(RestartButton);

  Game2DControls := TGame2DControls.Create(Application);
  Window.Controls.InsertFront(Game2DControls);

  GoingUpImage := TCastleImageControl.Create(Application);
  GoingUpImage.URL := 'castle-data:/ui/going_up.png';
  Window.Controls.InsertFront(GoingUpImage);

  { Disable some default input shortcuts defined by CastleSceneManager.
    They will not do anything if we don't use the related functionality
    (if we don't put anything into the default Player.Inventory),
    but it's a little cleaner to still disable them to avoid spurious
    warnings like "No weapon equipped" on each press of Ctrl key. }
  PlayerInput_Attack.MakeClear(true);
  PlayerInput_InventoryShow.MakeClear(true);
  PlayerInput_InventoryPrevious.MakeClear(true);
  PlayerInput_InventoryNext.MakeClear(true);
  PlayerInput_UseItem.MakeClear(true);
  PlayerInput_DropItem.MakeClear(true);
  PlayerInput_CancelFlying.MakeClear(true);

  OnCreatureExists := @TGame(nil).CreatureExists;
end;

const
  AliveTouchInterface =
    {$ifdef TOUCH_INTERFACE} tiCtlWalkDragRotate; {$else} tiNone; {$endif}
    { tiNone;
      For this game, tiNone is too troublesome, as you often mistakenly
      do walk/rotate when you want to do only the other thing.
      It's important here, as accidental movement moves you away from light,
      which has (deadly) gameplay consequences :) }

procedure GameStart;
var
  Walk: TCastleWalkNavigation;
begin
  GameWin := false;

  { really reload, to apply new Quality setting }
  SceneManager.UnloadLevel;

  case Quality of
    qBeautiful:
      begin
        BakedAnimationSmoothness := 1.0;
        GLTextureScale := 1;
      end;
    qAverage:
      begin
        BakedAnimationSmoothness := 0.75;
        GLTextureScale := 1;
      end;
    qFastest:
      begin
        BakedAnimationSmoothness := 0.5;
        GLTextureScale := 2;
      end;
    else raise EInternalError.Create('quality?');
  end;

  if Player <> nil then
    FreeAndNil(Player); // SceneManager references will be cleared automatically
  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  SceneManager.LoadLevel('1');

  { just for test, load 3D model without the CastleLevels stuff }
  // Window.Load('castle-data:/level/1/level1_final.x3dv');
  // Window.MainScene.Spatial := [ssRendering, ssDynamicCollisions];
  // Window.MainScene.ProcessEvents := true;

  { SceneManager.LoadLevel always initializes Navigation, always to TCastleWalkNavigation }
  Walk := SceneManager.Navigation as TCastleWalkNavigation;
  Walk.MouseDraggingHorizontalRotationSpeed := 0.5 / (Window.Dpi / DefaultDPI);
  Walk.MouseDraggingVerticalRotationSpeed := 0;
  Player.EnableCameraDragging := true;
end;

procedure PlayResize(Window: TCastleWindowTouch);
begin
  RestartButton.Center;
  GoingUpImage.Center;
end;

procedure PlayUpdate(Window: TCastleWindowTouch);
const
  RegenerateSpeed = 1.8; // life points per second you gain
begin
  SceneManager.Exists := not Options;
  Game2DControls.Exists := not Options;

  RestartButton.Exists := (not Options) and (Player.Dead or GameWin);

  GoingUpImage.Exists := (not Options) and (not RestartButton.Exists) and GoingUp;
  { Reset GoingUp every frame. If we're still GoingUp, it will be set again
    to true before next check above. }
  GoingUp := false;

  if (not Options) and (not Player.Dead) then
  begin
    Window.TouchInterface := AliveTouchInterface;
    Player.Life := Min(Player.MaxLife,
      Player.Life + Window.Fps.SecondsPassed * RegenerateSpeed);
  end else
    Window.TouchInterface := tiNone;
end;

end.
