{
  anari-sdk,
  cmake,
  apple-sdk_14,
  fetchFromGitHub,
  lib,
  python3,
  stdenv,
  openusd,
  opensubdiv,
  materialx,
  libGL,
  mdl-sdk,
  xorg,
  tbb,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "hdanari";
  version = "0.15.0-unstable-2025-11-20";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "1a579bb080c2d9ee07edfc62db82f91494705be4";
    hash = "sha256-Uq33CaJHtgyo2/trs56lzh+uER6TBUtTr3kKXBeXKf8=";
  };

  sourceRoot = "source/src/hdanari";

  patches = [
    ./0001-hdanari-Fix-CMakeLists-and-MacOS-build.patch
  ];

  patchFlags = [ "-p3" ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    materialx
    openusd
    opensubdiv
    tbb
  ]
  ++ lib.optionals stdenv.isLinux [
    # What's need for MaterialX on Linux
    xorg.libX11
    xorg.libXt
    libGL

    # MDL-SDK is broken on aarch64-darwin due to
    # removed clang12.
    mdl-sdk
  ]
  ++ lib.optionals stdenv.isDarwin [
    apple-sdk_14
  ];

  cmakeFlags = [
    (lib.cmakeBool "HDANARI_ENABLE_MDL" (!stdenv.isDarwin))
  ];

  # Special case for OPENUSD_PLUGIN_INSTALL_PREFIX...
  # Ideally we'd like to pass this as a relative path to the installation folder in the cmakeFlags, but this does end up
  # installing in the build folder instead of the output folder.
  # Quoting CMake documentation from https://cmake.org/cmake/help/latest/command/set.html:
  #   Furthermore, if the <type> is PATH or FILEPATH and the <value> provided
  #   on the command line is a relative path, then the set command will treat
  #   the path as relative to the current working directory and convert it to an absolute path.
  # Passing $out to cmakeFlags does not work as $out is escaped but then never evaluated. It then means that
  # installation files go to the litteral $out subfolder of the build tree, as per the above.
  # So, we get that through a custom configurePhase enforcing that value to the cmake flags when $out can be shell evaluated.
  configurePhase = ''
    prependToVar cmakeFlags "-DOPENUSD_PLUGIN_INSTALL_PREFIX=$prefix/plugin/usd"
    cmakeConfigurePhase
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "HdAnari is USD Hydra Render delegate enabling the use of ANARI devices inside USD.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
