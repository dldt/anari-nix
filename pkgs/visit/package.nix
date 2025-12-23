{
  adwaita-qt,
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

  rversion = "3.4.9";
in
stdenv.mkDerivation {
  pname = "visit";
  version = "3.4.0-934-g68668d3586";

  src = fetchFromGitHub {
    owner = "visit-dav";
    repo = "visit";
    rev = "68668d35863691507218443c329ad1467aa7595c";
    hash = "sha256-9MjOkdlWdi092UE9eYtuI2YfzVRfwg8QDxZHzmxdBpY=";
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
    (lib.getDev hdf5)
    (lib.getDev vtkWithQt6)
    adwaita-qt
    hdf5
    libGL
    libxcb-cursor
    python3
    python3
    python3Packages.distutils
    python3Packages.numpy
    python3Packages.pip
    python3Packages.setuptools
    qt6.qtbase
    qt6.qtsvg
    qt6.qttools
    silo
    vtkWithQt6
    xorg.libX11
    xorg.libxcb.dev
  ];

  dontWrapQtApps = true;

  qtWrapperArgs = [
    "--set QT_STYLE_OVERRIDE adwaita-dark"
  ];

  postInstall = ''
    mkdir -p $out/bin
    ln -s ${lib.getExe python3} $out/${rversion}/linux-x86_64/bin/python3
  '';

  preFixup = ''
    ln -s libsiloh5.so.4.12.0 $out/${rversion}/linux-x86_64/lib/libsiloh5.so.412 

    for exe in gui mcurvit qtviswinExample qtvtkExample qvtkopenglExample xmledit viewer
    do
      wrapQtApp "$out/${rversion}/linux-x86_64/bin/$exe"
    done    
  '';

  postFixup = ''
    patchShebangs $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=skip"
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
