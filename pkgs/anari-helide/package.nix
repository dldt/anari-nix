{
  anari-sdk,
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  embree,
  python3,
  nix-update-script,
}:
let
  embree_for_helide-src = fetchurl {
    url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip";
    hash = "sha256-Y9ZOWHlb3fbpxWT2aJVky4WHaU4CXn7HeQdyzIIYs7k=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide";
  version = "0.16.0-unstable-2026-08-13";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "7897cbe425e5000ce890631bc97d14e00c750175";
    hash = "sha256-UkqF60Is92qGzzMekV8jcN6a1AytQ8Zy4J33WDKUCj0=";
  };
  sourceRoot = "source/src/devices/helide";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_embree/"
    cp "${embree_for_helide-src}" "''${sourceRoot}/.anari_deps/anari_helide_embree/v4.3.3.zip"
  '';

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    embree
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Helide device, embree based, for ANARI.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
