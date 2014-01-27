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

{ Game playing logic (as opposed to logic in the options menu). }
unit GamePlay;

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

uses SysUtils, CastleControls, CastleUIControls, CastleVectors,
  CastleColors, CastleFilesUtils, CastleLog, CastleSceneCore, CastleImages,
  CastleResources, CastleGLUtils, CastleUtils, CastleRectangles, CastleCameras,
  CastleSceneManager, CastlePrecalculatedAnimation, CastleGLImages, GameOptions,
  Game,
  GameLevels { use, to run GameLevels initialization, to register level logic };

var
  GoingUpImage: TCastleImageControl;

{ TGame2DControls ------------------------------------------------------------ }

const
  UIMargin = 10;

type
  TGame2DControls = class(TUIControl)
  public
    procedure Draw; override;
    function RenderStyle: TRenderStyle; override;
  end;

function TGame2DControls.RenderStyle: TRenderStyle;
begin
  Result := rs2D;
end;

procedure TGame2DControls.Draw;
var
  R: TRectangle;
begin
  if not GetExists then Exit;

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
  Start(true);
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

{ Play globals --------------------------------------------------------------- }

procedure PlayInitialize(Window: TCastleWindowTouch);
begin
  SceneManager := Window.SceneManager;

  //Resources.LoadFromFiles; // cannot search recursively in Android assets
  Resources.AddFromFile(ApplicationData('creatures/light/resource.xml'));
  ResourceHarpy := Resources.FindName('Harpy') as TWalkAttackCreatureResource;

  //Levels.LoadFromFiles; // cannot search recursively in Android assets
  Levels.AddFromFile(ApplicationData('level/1/level.xml'));

  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := '';
  RestartButton.Image := LoadImage(ApplicationData('ui/restart.png'));
  RestartButton.OwnsImage := true;
  Window.Controls.InsertFront(RestartButton);

  Game2DControls := TGame2DControls.Create(Application);
  Window.Controls.InsertFront(Game2DControls);

  GoingUpImage := TCastleImageControl.Create(Application);
  GoingUpImage.URL := ApplicationData('ui/going_up.png');
  Window.Controls.InsertFront(GoingUpImage);

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

const
  AliveTouchInterface = etciCtlWalkDragRotate;
    { etciNone;
      For this game, etciNone is too troublesome, as you often mistakenly
      do walk/rotate when you want to do only the other thing.
      It's important here, as accidental movement moves you away from light,
      which has (deadly) gameplay consequences :) }

procedure GameStart;
var
  Walk: TWalkCamera;
begin
  GameWin := false;

  { really reload, to apply new Quality setting }
  SceneManager.UnloadLevel;

  case Quality of
    qBeautiful:
      begin
        AnimationSmoothness := 1.0;
        GLTextureScale := 1;
      end;
    qAverage:
      begin
        AnimationSmoothness := 0.75;
        GLTextureScale := 1;
      end;
    qFastest:
      begin
        AnimationSmoothness := 0.5;
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
  // Window.Load(ApplicationData('level/1/level1_final.x3dv'));
  // Window.MainScene.Spatial := [ssRendering, ssDynamicCollisions];
  // Window.MainScene.ProcessEvents := true;

  { SceneManager.LoadLevel always initializes Camera, always to TWalkCamera }
  Walk := SceneManager.Camera as TWalkCamera;
  Walk.MouseDraggingHorizontalRotationSpeed := 0.5;
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
      Player.Life + Window.Fps.UpdateSecondsPassed * RegenerateSpeed);
  end else
    Window.TouchInterface := etciNone;
end;

end.