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
const
  { Heyzap publisher id.

    Do *not* simply copy-paste string below into your own games!
    The value below is connected with me and the revenue from ads goes to me,
    the "Darkest Before the Dawn" author.

    If you want to use Heyzap for your own games, you need to register
    on Heyzap, add your applications on http://heyzap.com/ ,
    and get the magic id for your app from your Heyzap account. }
  HeyzapPublisherId = '101475e09025a48b0f2a80eff9f05e7b';
begin
  Ads.InitializeHeyzap(HeyzapPublisherId);
end;

procedure AdShowFullScreen;
begin
  Ads.ShowFullScreenAd(anHeyzap, atInterstitialVideo, false);
end;

initialization
  Ads := TAds.Create(nil);
finalization
  FreeAndNil(Ads);
end.
