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

{ Level-specific logic. }
unit GameLevels;

interface

uses Classes, DOM, Generics.Collections,
  CastleLevels, CastleTransform, CastleTransformExtra, CastleScene, CastleShapes,
  CastleResources, CastleVectors, X3DNodes, CastleBoxes, X3DFields;

type
  TLevel1 = class(TLevelLogic)
  strict private
    type
      TElevator = class
      strict private
        Moving: TCastleLinearMoving;
        Scene: TCastleScene;
        FName: string;
        FAchievementId: string;
      public
        constructor Create(const AName: string; const Level: TAbstractLevel;
          const Owner: TLevel1; const Height: Single;
          const AnAchievementId: string = '');
        procedure Update;
      end;
      TElevatorList = specialize TObjectList<TElevator>;

    var
      Elevators: TElevatorList;
      Lights: TVector3List;
      BrightnessDistanceFactor, BackgroundMorning: TSFFloat;
      MorningEmpty, MorningFull: TVector3;
      GameWinBox: TBox3D;
  public
    constructor Create(const AOwner: TComponent;
      const ALevel: TAbstractLevel;
      const MainScene: TCastleScene; const DOMElement: TDOMElement); override;
    destructor Destroy; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
    function Placeholder(const Shape: TShape;
      const PlaceholderName: string): boolean; override;
  end;

implementation

uses SysUtils,
  CastleFilesUtils, CastleStringUtils, CastleUtils, CastleLog,
  GamePlay, GameOptions, GameGooglePlayGames;

{ TLevel1.TElevator ---------------------------------------------------------- }

constructor TLevel1.TElevator.Create(const AName: string; const Level: TAbstractLevel;
  const Owner: TLevel1; const Height: Single; const AnAchievementId: string);
begin
  inherited Create;

  FName := AName;
  FAchievementId := AnAchievementId;

  Scene := Owner.LoadLevelScene('castle-data:/level/1/' + FName, true);

  Moving := TCastleLinearMoving.Create(Owner);
  Moving.Add(Scene);
  Moving.MoveTime := Height / 3.0;
  Moving.TranslationEnd := Vector3(0, Height, 0);
  Level.RootTransform.Add(Moving);
end;

procedure TLevel1.TElevator.Update;
var
  PlayerInside: boolean;
begin
  PlayerInside := Scene.BoundingBox.Contains2D(ViewPlay.Player.Translation, 1);
  if Moving.CompletelyBeginPosition and PlayerInside then
  begin
    Moving.GoEndPosition;
    WritelnLog('Elevator', 'Moving the elevator ' + FName + ', achievement ' + FAchievementId);
    if FAchievementId <> '' then
      GooglePlayGames.Achievement(FAchievementId);
  end else
  if Moving.CompletelyEndPosition and not PlayerInside then
  begin
    Moving.GoBeginPosition;
  end else
  if PlayerInside and
     (not Moving.CompletelyEndPosition) and
     (not Moving.CompletelyBeginPosition) then
    ViewPlay.GoingUp := true;
end;

{ TLevel1 -------------------------------------------------------------------- }

constructor TLevel1.Create(const AOwner: TComponent;
  const ALevel: TAbstractLevel;
  const MainScene: TCastleScene; const DOMElement: TDOMElement);
var
  GammaVal: Single;
  BrightnessInvGamma: TSFFloat;
begin
  inherited;
  Elevators := TElevatorList.Create(true);
  Elevators.Add(TElevator.Create('stages/tube/elevator_1.x3d'    , ALevel, Self, 10, AchievementStage1));
  Elevators.Add(TElevator.Create('stages/street/elevator_1.x3d'  , ALevel, Self, 10, AchievementStage2));
  Elevators.Add(TElevator.Create('stages/street/elevator_2.x3d'  , ALevel, Self, 10, AchievementStage2));
  Elevators.Add(TElevator.Create('stages/outdoors/elevator_1.x3d', ALevel, Self, 10, AchievementStage3));
  Elevators.Add(TElevator.Create('stages/above/elevator_1.x3d'   , ALevel, Self, 10, AchievementStage4));
  Elevators.Add(TElevator.Create('stages/above/elevator_2.x3d'   , ALevel, Self, 10));
  Elevators.Add(TElevator.Create('stages/above/elevator_3.x3d'   , ALevel, Self, 10));
  Elevators.Add(TElevator.Create('stages/above/elevator_4.x3d'   , ALevel, Self, 10));
  Lights := TVector3List.Create;

  BrightnessDistanceFactor := MainScene.Field('BrightnessEffect', 'distance_factor') as TSFFloat;
  BackgroundMorning := MainScene.Field('BackgroundEffect', 'morning') as TSFFloat;
  BrightnessInvGamma := MainScene.Field('BrightnessEffect', 'inv_gamma') as TSFFloat;

  case Gamma of
    gDarkest  : GammaVal := 1.0;
    gAverage  : GammaVal := 1.3;
    gBrightest: GammaVal := 1.6;
    else raise EInternalError.Create('Gamma??');
  end;

  BrightnessInvGamma.Send(1 / GammaVal);
end;

destructor TLevel1.Destroy;
begin
  FreeAndNil(Elevators);
  FreeAndNil(Lights);
  inherited;
end;

procedure TLevel1.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
var
  E: TElevator;
  DistanceToClosestLight, S, DistanceFactor, MorningFactor: Single;
  PlayerPos, Projected: TVector3;
  I: Integer;
const
  DistanceToSecurity = 4.0;
  DistanceToDanger = 8.0;
begin
  inherited;
  if ViewPlay.Player = nil then Exit; // paranoia, TODO: check, possibly not needed
  for E in Elevators do
    E.Update;

  PlayerPos := ViewPlay.Player.Translation;

  { calculate and use distance to the nearest light source }

  DistanceToClosestLight := 10000; // not just MaxSingle, since we will Sqr this
  for I := 0 to Lights.Count - 1 do
  begin
    S := PointsDistanceSqr(Lights.L[I], PlayerPos);
    if S < Sqr(DistanceToClosestLight) then
      DistanceToClosestLight := Sqrt(S);
  end;

  DistanceFactor := SmoothStep(DistanceToSecurity, DistanceToDanger,
    DistanceToClosestLight);

  BrightnessDistanceFactor.Send(DistanceFactor);

  if DistanceFactor < 0.5 then
  begin
    ViewPlay.ResourceHarpy.RunAwayLife := 10.0 { anything >= 1.0, to run always };
    ViewPlay.ResourceHarpy.RunAwayDistance := MapRange(DistanceFactor, 0.0, 0.5,
      100, 10);
  end else
    ViewPlay.ResourceHarpy.RunAwayLife := 0.0 { never run };

  { calculate and use "morning", which shows player progress on skybox }
  Projected := PointOnLineClosestToPoint(MorningEmpty, MorningFull, PlayerPos);
  MorningFactor := PointsDistance(MorningEmpty, Projected) /
                   PointsDistance(MorningEmpty, MorningFull);
  ClampVar(MorningFactor, 0, 1);
  BackgroundMorning.Send(MorningFactor);

  if GameWinBox.Contains(PlayerPos) then
  begin
    if not ViewPlay.GameWin then
    begin
      GooglePlayGames.Achievement(AchievementWin);
      ViewPlay.GameWin := true;
    end;
  end;
end;

function TLevel1.Placeholder(const Shape: TShape;
  const PlaceholderName: string): boolean;
begin
  Result := inherited;
  if Result then Exit;

  if IsPrefix('LightPos', PlaceholderName) then
  begin
    Lights.Add(Shape.BoundingBox.Center);
    Exit(true);
  end;

  if PlaceholderName = 'MorningEmpty' then
  begin
    MorningEmpty := Shape.BoundingBox.Center;
    Exit(true);
  end;

  if PlaceholderName = 'MorningFull' then
  begin
    MorningFull := Shape.BoundingBox.Center;
    Exit(true);
  end;

  if PlaceholderName = 'GameWin' then
  begin
    GameWinBox := Shape.BoundingBox;
    Exit(true);
  end;
end;

initialization
  { register our level logic classes }
  LevelLogicClasses['Level1'] := TLevel1;
end.
