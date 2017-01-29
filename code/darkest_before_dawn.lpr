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

{ Library to run the game on Android. }
library darkest_before_dawn;
uses CastleAndroidNativeAppGlue, Game, CastleMessaging;
exports
  Java_net_sourceforge_castleengine_MainActivity_jniMessage,
  ANativeActivity_onCreate;
end.
