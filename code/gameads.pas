{
  Copyright 2015-2015 Michalis Kamburelis.

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
procedure AdShowInterstitial;

implementation

uses SysUtils,
  CastleAds;

var
  Ads: TAds;

procedure AdInitialize;
const
  { Chartboost application id/signature.

    Do *not* simply copy-paste strings below into your own games.
    The values below are connected with my "Darkest Before the Dawn",
    and the revenue from ads goes to me, the "Darkest Before the Dawn" author.

    If you want to use Chartboost for your own games, you need to register
    on Chartboost, add your application on https://dashboard.chartboost.com/ ,
    and get the magic strings for your app from your Chartboost dashboard. }
  ChartboostAppId = '5656a979883809705c3673e2';
  ChartboostAppSignature = '477892e78faa64cc4c9789f8be64d4236bc6ace9';
begin
  Ads.InitializeChartboost(ChartboostAppId, ChartboostAppSignature);
end;

procedure AdShowInterstitial;
begin
  Ads.ShowInterstitial(atChartboost, false);
end;

initialization
  Ads := TAds.Create(nil);
finalization
  FreeAndNil(Ads);
end.
