"Darkest Before the Dawn", a scary game written using Castle Game Engine
(http://castle-engine.sourceforge.net/) for TenSquareGames game jam.

Everything (code and data) is open-source, by Michalis Kamburelis,
licensed on GNU GPL >= 2.0. Except some data files that are on
various Creative Commons licenses (look for AUTHORS.txt inside data/).

Compiling:

- Standalone (Linux, Windows, MacOSX, FreeBSD...):
  You just need FPC (Free Pascal Compiler), version >= 2.6.0,
  from freepascal.org or your Linux distro package manager.
  Run "make" in this directory to compile.

- Android: You need Android SDK, NDK and FPC cross-compiler to Android+Arm.
  Then run this:

  cd code/android/
  make init # one time only
  make data # upload data to device
  make # compile the library and then apk, install and run

  More detailed instuctions about Android setup will be available
  at Castle Game Engine website at some point.
  For now, just ask Michalis :)
