{ lib
, stdenv
, cmake
, ninja
, pkg-config
, qtbase
, qtdeclarative
, qtsvg
, wrapQtAppsHook
}:

stdenv.mkDerivation {
  pname = "oem-setup-linux";
  version = "0.1.0";

  src = lib.cleanSource ../.;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    qtsvg
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
  ];

  meta = {
    description = "First-boot OEM setup wizard for Linux";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
