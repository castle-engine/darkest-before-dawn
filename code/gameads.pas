{
  Copyright 2015-2017 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Advertisements in game. }
unit GameAds;

interface

procedure AdInitialize;
procedure AdShowFullScreen;

implementation

uses SysUtils,
  CastleAds;

var
  Ads: TAds;

procedure AdInitialize;
begin
  // No ads now.
end;

procedure AdShowFullScreen;
begin
  // No ads now.
end;

initialization
  Ads := TAds.Create(nil);
finalization
  FreeAndNil(Ads);
end.
