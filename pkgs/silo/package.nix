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
  version = "4.12.0";

  src = fetchFromGitHub {
    owner = "LLNL";
    repo = "Silo";
    rev = version;
    hash = "sha256-t9J4Y05QOTG0izmo2J2W62f5wg3R8CKP1ROiGwTg/lQ=";
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
