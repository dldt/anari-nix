{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  perl,
  hdf5,
  qt6,
}:

stdenv.mkDerivation rec {
  pname = "silo";
  version = "4.12.1-pre2";

  src = fetchFromGitHub {
    owner = "LLNL";
    repo = "Silo";
    rev = version;
    hash = "sha256-z3ds9205tb9S13Q0cpquIST2fc9l5epHF5RAVR7qkuc=";
  };

  nativeBuildInputs = [
    cmake
    perl
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    hdf5
    qt6.qtbase
  ];

  cmakeFlags = with lib; [
    (cmakeBool "SILO_ENABLE_SILEX" true)
    (cmakeBool "SILO_ENABLE_FORTRAN" false)
    (cmakeBool "SILO_USE_HDF5" true)
    (cmakeBool "SILO_ENABLE_BROWSER" false)
    (cmakeBool "SILO_ENABLE_INSTALL_LITE_HEADERS" true)
  ];

  meta = {
    description = "Mesh and Field I/O Library and Scientific Database";
    homepage = "https://github.com/LLNL/Silo";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "silo";
    platforms = lib.platforms.all;
  };
}
