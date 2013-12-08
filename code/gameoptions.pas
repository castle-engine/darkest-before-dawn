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

implementation

uses SysUtils, Classes, CastleControls, CastleUIControls, CastleImages,
  CastleFilesUtils, Game;

type
  TGamma = (gDarkest, gMiddle, gBrightest);

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

{ Options globals ------------------------------------------------------------ }

var
  OptionsControls: TUIControlList;
  QualityTitle: TCastleImageControl;

procedure OptionsInitialize(Window: TCastleWindow);
var
  Q: TQuality;
  QB: TQualityButton;
  Background: TCastleImageControl;
begin
  OptionsControls := TUIControlList.Create(false);

  Background := TCastleImageControl.Create(Application);
  Background.URL := ApplicationData('ui/options_bg.png');
  Background.Stretch := true;
  Background.FullSize := true;
  Window.Controls.InsertFront(Background);
  OptionsControls.Add(Background);

  QualityTitle := TCastleImageControl.Create(Application);
  QualityTitle.URL := ApplicationData('ui/quality_title.png');
  Window.Controls.InsertFront(QualityTitle);
  OptionsControls.Add(QualityTitle);

  PlayButton := TPlayButton.Create(Application);
  PlayButton.Image := LoadImage(ApplicationData('ui/play.png'));
  PlayButton.OwnsImage := true;
  Window.Controls.InsertFront(PlayButton);
  OptionsControls.Add(PlayButton);

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
  Margin = 10;
var
  CurrentBottom, OptionsHeight: Integer;
  QB: TQualityButton;
begin
  OptionsHeight := (QualityTitle.Rect.Height + Margin) * 4 + Margin * 2 +
    PlayButton.Height;
  CurrentBottom := (Window.Height + OptionsHeight) div 2;

  PlayButton.Left := (Window.Width - PlayButton.Rect.Width) div 2;
  PlayButton.Bottom := CurrentBottom;
  CurrentBottom -= PlayButton.Rect.Height + Margin * 2;

  QualityTitle.Left := (Window.Width - QualityTitle.Rect.Width) div 2;
  QualityTitle.Bottom := CurrentBottom;
  CurrentBottom -= QualityTitle.Rect.Height + Margin;

  for QB in TQualityButton.Buttons do
  begin
    QB.Left := (Window.Width - QB.Rect.Width) div 2;
    QB.Bottom := CurrentBottom;
    CurrentBottom -= QB.Rect.Height + Margin;
  end;
end;

finalization
  FreeAndNil(OptionsControls);
end.