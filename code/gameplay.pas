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

{ Game playing logic (as opposed to logic in the options menu). }
unit GamePlay;

interface

uses Classes,
  CastlePlayer, CastleLevels, CastleCreatures, CastleViewport, CastleUiControls,
  CastleControls;

type
  TViewPlay = class(TCastleView)
  private
    SceneManager: TGameSceneManager;
    TouchNavigation: TCastleTouchNavigation;
    RestartButton: TCastleButton;
    procedure ClickRestart(Sender: TObject);
  public
    Player: TPlayer;
    GameWin: boolean;
    GoingUp: boolean; // set by level logic
    ResourceHarpy: TWalkAttackCreatureResource;
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    procedure RenderOverChildren; override;
  end;

var
  ViewPlay: TViewPlay;

implementation

uses SysUtils, Math,
  CastleVectors,
  CastleColors, CastleFilesUtils, CastleLog, CastleSceneCore, CastleImages,
  CastleResources, CastleGLUtils, CastleUtils, CastleRectangles, CastleCameras,
  CastleSceneManager, X3DLoad, CastleGLImages, GameOptions, CastleTransform,
  CastleApplicationProperties,
  Game,
  GameLevels { use, to run GameLevels initialization, to register level logic };

var
  GoingUpImage: TCastleImageControl;

const
  UIMargin = 10;

{ TViewPlay --------------------------------------------------------------- }

constructor TViewPlay.Create(AOwner: TComponent);
begin
  inherited;

  // old engine could not search recursively in Android assets, though we can now
  //Resources.LoadFromFiles;
  Resources.AddFromFile('castle-data:/creatures/light/resource.xml');
  ResourceHarpy := Resources.FindName('Harpy') as TWalkAttackCreatureResource;

  // old engine could not search recursively in Android assets, though we can now
  //Levels.LoadFromFiles;
  Levels.AddFromFile('castle-data:/level/1/level.xml');
end;

procedure TViewPlay.Start;
var
  Walk: TCastleWalkNavigation;
begin
  inherited;

  SceneManager := TGameSceneManager.Create(FreeAtStop);
  SceneManager.FullSize := true;
  InsertFront(SceneManager);

  TouchNavigation := TCastleTouchNavigation.Create(FreeAtStop);
  // TouchNavigation.AutoTouchInterface := true; // leave false, GamePlay adjusts TouchNavigation.TouchInterface
  TouchNavigation.Viewport := SceneManager;
  TouchNavigation.FullSize := true;
  SceneManager.InsertFront(TouchNavigation);

  RestartButton := TCastleButton.Create(FreeAtStop);
  RestartButton.Caption := '';
  RestartButton.Image.URL := 'castle-data:/ui/restart.png';
  RestartButton.Anchor(hpMiddle);
  RestartButton.Anchor(vpMiddle);
  RestartButton.OnClick := {$ifdef FPC}@{$endif} ClickRestart;
  InsertFront(RestartButton);

  GoingUpImage := TCastleImageControl.Create(FreeAtStop);
  GoingUpImage.URL := 'castle-data:/ui/going_up.png';
  GoingUpImage.Anchor(hpMiddle);
  GoingUpImage.Anchor(vpMiddle);
  InsertFront(GoingUpImage);

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

  Player := TPlayer.Create(SceneManager);
  SceneManager.Player := Player;

  SceneManager.LoadLevel('1');

  { TODO: for some reason, this is too bright with PhongShading.
    Should investigate better why it happens. }
  SceneManager.Items.MainScene.RenderOptions.PhongShading := false;

  { just for test, load 3D model without the CastleLevels stuff }
  // Window.Load('castle-data:/level/1/level1_final.x3dv');
  // Window.MainScene.Spatial := [ssRendering, ssDynamicCollisions];
  // Window.MainScene.ProcessEvents := true;

  { SceneManager.LoadLevel always initializes Navigation, always to TCastleWalkNavigation }
  Walk := SceneManager.Navigation as TCastleWalkNavigation;
  // do not walk on drag, it would be too easy to accidentally walk wrong, e.g. step off elevator
  Walk.MouseDragMode := mdRotate;
  Walk.MouseDraggingHorizontalRotationSpeed := TCastleWalkNavigation.DefaultMouseDraggingHorizontalRotationSpeed * 3;
  Walk.MouseDraggingVerticalRotationSpeed := 0;
  Player.EnableNavigationDragging := true;
end;

procedure TViewPlay.Update(const SecondsPassed: Single; var HandleInput: boolean);

  function AliveTouchInterface: TTouchInterface;
  begin
    if ApplicationProperties.TouchDevice then
      Result := tiWalk
    else
      Result := tiNone;

    { For this game, moving too easy by accident is too troublesome,
      as you often mistakenly
      do walk/rotate when you want to do only the other thing.
      It's important here, as accidental movement moves you away from light,
      which has (deadly) gameplay consequences :) }
  end;

const
  RegenerateSpeed = 1.8; // life points per second you gain
  DistanceToActivateCreatures = 100.0;
var
  Creature: TCastleTransform;
begin
  inherited;

  RestartButton.Exists := Player.Dead or GameWin;

  GoingUpImage.Exists := (not RestartButton.Exists) and GoingUp;
  { Reset GoingUp every frame. If we're still GoingUp, it will be set again
    to true before next check above. }
  GoingUp := false;

  if not Player.Dead then
  begin
    TouchNavigation.TouchInterface := AliveTouchInterface;
    Player.Life := Min(Player.MaxLife,
      Player.Life + Container.Fps.SecondsPassed * RegenerateSpeed);
  end else
    TouchNavigation.TouchInterface := tiNone;

  { optimize creature processing, don't process far creatures }
  for Creature in SceneManager.LevelProperties.CreaturesRoot do
    Creature.Exists := PointsDistanceSqr(Creature.Translation, Player.Translation) <=
      Sqr(DistanceToActivateCreatures);
end;

procedure TViewPlay.RenderOverChildren;
var
  R: TRectangle;
begin
  inherited;

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

procedure TViewPlay.ClickRestart(Sender: TObject);
var
  SavedContainer: TCastleContainer;
begin
  { Restart TViewPlay.
    Stop us, then start us, by assigning to Container.View first nil, then Self.
    Note that we have to save Container to SavedContainer,
    because after stopping, the Container changes to nil. }
  SavedContainer := Container;
  Container.View := nil;
  SavedContainer.View := Self;
end;

end.
