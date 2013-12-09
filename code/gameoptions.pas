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

{ Options variables and GUI. }
unit GameOptions;

interface

uses CastleWindow;

var
  Options: boolean;

{ Create options GUI. }
procedure OptionsInitialize(Window: TCastleWindow);

{ Called every frame.
  Update Exists state of options GUI, based on Options value. }
procedure OptionsUpdate(Window: TCastleWindow);

{ Resize options GUI to current window sizes. }
procedure OptionsResize(Window: TCastleWindow);

type
  TQuality = (qBeautiful, qAverage, qFastest);

function Quality: TQuality;

type
  TGamma = (gDarkest, gAverage, gBrightest);

function Gamma: TGamma;

implementation

uses SysUtils, Classes, CastleControls, CastleUIControls, CastleImages,
  CastleFilesUtils, Game;

{ Play button ---------------------------------------------------------------- }

type
  TPlayButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

procedure TPlayButton.DoClick;
begin
  Start(false);
end;

var
  PlayButton: TPlayButton;

{ Quality -------------------------------------------------------------------- }

const
  QualityNames: array [TQuality] of string = ('beautiful', 'average', 'fastest');

var
  FQuality: TQuality = qBeautiful;

function Quality: TQuality;
begin
  Result := FQuality;
end;

type
  TQualityButton = class(TCastleButton)
  public
    class var
      Buttons: array [TQuality] of TQualityButton;
    var
      Value: TQuality;

    constructor Create(AOwner: TComponent); override;
    procedure DoClick; override;
  end;

constructor TQualityButton.Create(AOwner: TComponent);
begin
  inherited;
  Toggle := true;
end;

procedure TQualityButton.DoClick;
var
  B: TQualityButton;
begin
  FQuality := Value;
  for B in Buttons do
    B.Pressed := B = Self;
end;

{ Gamma -------------------------------------------------------------------- }

const
  GammaNames: array [TGamma] of string = ('darkest', 'average', 'brightest');

var
  FGamma: TGamma = gDarkest;

function Gamma: TGamma;
begin
  Result := FGamma;
end;

type
  TGammaButton = class(TCastleButton)
  public
    class var
      Buttons: array [TGamma] of TGammaButton;
    var
      Value: TGamma;

    constructor Create(AOwner: TComponent); override;
    procedure DoClick; override;
  end;

constructor TGammaButton.Create(AOwner: TComponent);
begin
  inherited;
  Toggle := true;
end;

procedure TGammaButton.DoClick;
var
  B: TGammaButton;
begin
  FGamma := Value;
  for B in Buttons do
    B.Pressed := B = Self;
end;

{ Options globals ------------------------------------------------------------ }

var
  OptionsControls: TUIControlList;
  QualityTitle, GammaTitle: TCastleImageControl;

procedure OptionsInitialize(Window: TCastleWindow);
var
  Q: TQuality;
  QB: TQualityButton;
  G: TGamma;
  GB: TGammaButton;
  Background: TCastleImageControl;
begin
  OptionsControls := TUIControlList.Create(false);

  Background := TCastleImageControl.Create(Application);
  Background.URL := ApplicationData('ui/options_bg.png');
  Background.Stretch := true;
  Background.FullSize := true;
  Window.Controls.InsertFront(Background);
  OptionsControls.Add(Background);

  PlayButton := TPlayButton.Create(Application);
  PlayButton.Image := LoadImage(ApplicationData('ui/play.png'));
  PlayButton.OwnsImage := true;
  Window.Controls.InsertFront(PlayButton);
  OptionsControls.Add(PlayButton);

  QualityTitle := TCastleImageControl.Create(Application);
  QualityTitle.URL := ApplicationData('ui/quality_title.png');
  Window.Controls.InsertFront(QualityTitle);
  OptionsControls.Add(QualityTitle);

  for Q in TQuality do
  begin
    QB := TQualityButton.Create(Application);
    QB.Value := Q;
    QB.Pressed := Q = Quality;
    QB.Image := LoadImage(ApplicationData('ui/quality_' + QualityNames[Q] + '.png'));
    QB.OwnsImage := true;
    QB.ImageMargin := 0;

    Window.Controls.InsertFront(QB);
    TQualityButton.Buttons[Q] := QB;
    OptionsControls.Add(QB);
  end;

  GammaTitle := TCastleImageControl.Create(Application);
  GammaTitle.URL := ApplicationData('ui/gamma_title.png');
  Window.Controls.InsertFront(GammaTitle);
  OptionsControls.Add(GammaTitle);

  for G in TGamma do
  begin
    GB := TGammaButton.Create(Application);
    GB.Value := G;
    GB.Pressed := G = Gamma;
    GB.Image := LoadImage(ApplicationData('ui/gamma_' + GammaNames[G] + '.png'));
    GB.OwnsImage := true;
    GB.ImageMargin := 0;

    Window.Controls.InsertFront(GB);
    TGammaButton.Buttons[G] := GB;
    OptionsControls.Add(GB);
  end;
end;

procedure OptionsUpdate(Window: TCastleWindow);
var
  C: TUIControl;
begin
  for C in OptionsControls do
    C.Exists := Options;
end;

procedure OptionsResize(Window: TCastleWindow);
const
  Margin = 8;
var
  CurrentBottom, OptionsHeight, QualityBottom, QualityLeft,
    GammaBottom, GammaLeft, OptionsWidth: Integer;
  QB: TQualityButton;
  GB: TGammaButton;
begin
  OptionsHeight := QualityTitle.Rect.Height + Margin * 2;
  for QB in TQualityButton.Buttons do
    OptionsHeight += QB.Rect.Height + Margin;
  OptionsHeight += PlayButton.Rect.Height;

  CurrentBottom := (Window.Height + OptionsHeight) div 2;

  OptionsWidth :=
    TQualityButton.Buttons[qAverage].Rect.Width + Margin * 2 +
    TGammaButton.Buttons[gAverage].Rect.Width;
  QualityLeft := (Window.Width - OptionsWidth) div 2;
  GammaLeft := QualityLeft + TQualityButton.Buttons[qAverage].Rect.Width + Margin * 2;

  CurrentBottom -= PlayButton.Rect.Height;
  PlayButton.Bottom := CurrentBottom;
  PlayButton.CenterHorizontal;

  QualityBottom := CurrentBottom;
  QualityBottom -= QualityTitle.Rect.Height + Margin * 3;
  QualityTitle.Bottom := QualityBottom;
  QualityTitle.Left := QualityLeft;
  QualityBottom += Margin; // smaller margin from 1st button

  for QB in TQualityButton.Buttons do
  begin
    QualityBottom -= QB.Rect.Height + Margin;
    QB.Bottom := QualityBottom;
    QB.Left := QualityLeft;
  end;

  GammaBottom := CurrentBottom;
  GammaBottom -= GammaTitle.Rect.Height + Margin * 3;
  GammaTitle.Bottom := GammaBottom;
  GammaTitle.Left := GammaLeft;
  GammaBottom += Margin; // smaller margin from 1st button

  for GB in TGammaButton.Buttons do
  begin
    GammaBottom -= GB.Rect.Height + Margin;
    GB.Bottom := GammaBottom;
    GB.Left := GammaLeft;
  end;
end;

finalization
  FreeAndNil(OptionsControls);
end.