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

{ Ids for integration with Google Play Game Services. }
unit GameGooglePlayGames;

interface

uses CastleGooglePlayGames;

const
  { Achievement codes you get from Google Games developer console. }
  AchievementStage1 = 'CgkI_a3v8dkdEAIQAg';
  AchievementStage2 = 'CgkI_a3v8dkdEAIQAw';
  AchievementStage3 = 'CgkI_a3v8dkdEAIQBA';
  AchievementStage4 = 'CgkI_a3v8dkdEAIQBQ';
  AchievementWin    = 'CgkI_a3v8dkdEAIQBg';

var
  GooglePlayGames: TGooglePlayGames;

implementation

uses SysUtils;

initialization
  GooglePlayGames := TGooglePlayGames.Create(nil);
finalization
  FreeAndNil(GooglePlayGames);
end.
