{
  autoPatchelfHook,
  cmake,
  fetchFromGitHub,
  hdf5,
  ispc,
  lib,
  libGL,
  libxcb-cursor,
  nix-update-script,
  python3,
  python3Packages,
  qt6,
  silo,
  stdenv,
  symlinkJoin,
  vtkWithQt6,
  xorg,
  zlib,
}:
let
  zlib-dev = symlinkJoin {
    name = "zlib-dev";
    paths = [
      zlib
      (lib.getDev zlib)
    ];
  };

  hdf5-dev = symlinkJoin {
    name = "hdf5-dev";
    paths = [
      hdf5
      (lib.getDev hdf5)
    ];
  };
in
stdenv.mkDerivation {
  pname = "visit";
  version = "3.3.0d-unstable-2025-12-12";

  src = fetchFromGitHub {
    owner = "visit-dav";
    repo = "visit";
    rev = "f676bbb82cb98e819bccf8b9e61fdbdd60fccadc";
    hash = "sha256-yA7qPMZOonv9Gyiqvdpx0oZ2M9vCJ/ThT49+D6AooZM=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-Don-t-pull-pip-when-building.patch
    ./0002-Fix-legacy-CMake-policy.patch
    ./20752.patch
  ];

  patchFlags = [ "-p2" ];

  sourceRoot = "source/src";

  cmakeFlags = with lib; [
    (cmakeBool "VISIT_ENABLE_DATAGEN" true)
    (cmakeBool "VISIT_ENABLE_LIBSIM" true)
    (cmakeBool "VISIT_ENABLE_MANUALS" false)
    (cmakeBool "VISIT_ENABLE_SILO_TOOLS" true)
    (cmakeBool "ENABLE_OPENMP" true)
    (cmakeFeature "VISIT_CONFIG_SITE" "None")
    (cmakeFeature "VISIT_ZLIB_DIR" "${zlib-dev}")
    (cmakeFeature "VISIT_QT_DIR" "${qt6.qtbase}")
    (cmakeFeature "VISIT_SILO_DIR" "${silo}")
    (cmakeFeature "VISIT_HDF5_DIR" "${hdf5-dev}")
    (cmakeFeature "VISIT_ISPC_DIR" "${ispc}")

    (cmakeBool "BUILD_CTEST_TESTING" false)
    (cmakeBool "ENABLE_TESTING" false)
    (cmakeBool "VISIT_PYTHON_SKIP_INSTALL" true)
    (cmakeBool "VISIT_HEADERS_SKIP_INSTALL" true)
    (cmakeBool "VISIT_QT_SKIP_INSTALL" true)
    (cmakeBool "VISIT_VTK_SKIP_INSTALL" true)
    (cmakeBool "VISIT_INSTALL_THIRD_PARTY" false)
  ];

  nativeBuildInputs = [
    cmake
    python3
    qt6.wrapQtAppsHook
    autoPatchelfHook
    ispc
  ];

  buildInputs = [
    python3
    libGL
    hdf5
    (lib.getDev hdf5)
    python3
    python3Packages.distutils
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.numpy
    qt6.qtbase
    qt6.qtsvg
    qt6.qttools
    vtkWithQt6
    (lib.getDev vtkWithQt6)
    xorg.libxcb.dev
    xorg.libX11
    libxcb-cursor
    silo
  ];

  postInstall = ''
    mkdir -p $out/bin
    ln -s ${lib.getExe python3} $out/3.4.9/linux-x86_64/bin/python3
  '';

  preFixup = ''
    ln -s libsiloh5.so.4.12.0 $out/3.4.9/linux-x86_64/lib/libsiloh5.so.412 
  '';

  postFixup = ''
    patchShebangs $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "VisIt - Visualization and Data Analysis for Mesh-based Scientific Data";
    homepage = "https://github.com/visit-dav/visit.git";
    license = licenses.bsd3;
    maintainers = [ ];
    mainProgram = "visit";
    platforms = platforms.linux;
  };
}
