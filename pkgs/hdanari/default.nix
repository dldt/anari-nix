{
  anari-sdk,
  cmake,
  darwin,
  fetchFromGitHub,
  lib,
  python3,
  stdenv,
  openusd,
  materialx,
  libGL,
  xorg,
  tbb,
}:
let
  anari-sdk-src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "0ddd2eecd591a874e8653af9cb80a1e8ecc7fb7d";
    hash = "sha256-uxVWxocZ8bWtleZp3QZgzmhUuIKgkMTv6AGSTgzkri8=";
  };
in
stdenv.mkDerivation {
  pname = " hdanari";
  version = "v0.13.1-4-g0ddd2ee";

  # Main source
  src = anari-sdk-src // {
    outPath = anari-sdk-src.outPath + "/src/hdanari";
  };

  patches = [ ./0001-Search-MaterialX-deps-on-Linux.patch ];
  patchFlags = [ "-p3" ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs =
    [
      anari-sdk
      materialx
      openusd
      tbb
    ]
    ++ lib.optionals stdenv.isLinux [
      # What's need for MaterialX on Linux
      xorg.libX11
      xorg.libXt
      libGL
    ]
    ++ lib.optionals stdenv.isDarwin (
      with darwin.apple_sdk_11_0.frameworks;
      [
        AppKit
        ApplicationServices
        Cocoa
        OpenGL
        Metal
      ]
    );

  cmakeFlags = [ "-DUSE_INSTANCE_ARRAYS=ON" ];

  # Special case for OPENUSD_INSTALL_PREFIX...
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
    prependToVar cmakeFlags "-DOPENUSD_INSTALL_PREFIX=$prefix/plugin/usd"
    cmakeConfigurePhase
  '';

  meta = with lib; {
    description = "HdAnari is USD Hydra Render delegate enabling the use of ANARI devices inside USD.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
