{
  anari-sdk,
  applyPatches,
  cmake,
  apple-sdk_11,
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
}:
let
  anari-sdk-src =
    let
      owner = "KhronosGroup";
      repo = "ANARI-SDK";
    in
    applyPatches {
      inherit owner repo;
      src = fetchFromGitHub {
        inherit owner repo;
        rev = "b7f09b0e0f55840397886ef556a3391d2239648b";
        hash = "sha256-3gy3q28CjOlipodzM71ElIiTW0qTaFsPZGdG2kiURVc=";
      };
    };
  hdanari-src = anari-sdk-src // {
    outPath = anari-sdk-src.outPath + "/src/hdanari";
  };
in
stdenv.mkDerivation {
  pname = "hdanari";
  version = "v0.14.1-20-gb7f09b0";

  # Main source
  src = hdanari-src;

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    materialx
    mdl-sdk
    openusd
    opensubdiv
    tbb
  ]
  ++ lib.optionals stdenv.isLinux [
    # What's need for MaterialX on Linux
    xorg.libX11
    xorg.libXt
    libGL
  ]
  ++ lib.optionals stdenv.isDarwin [
    apple-sdk_11
  ];

  cmakeFlags = [
    (lib.cmakeBool "HDANARI_ENABLE_MDL" true)
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

  meta = with lib; {
    description = "HdAnari is USD Hydra Render delegate enabling the use of ANARI devices inside USD.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
