{ stdenvNoCC }:
let
  src = ./FindTBB.cmake;
in
stdenvNoCC.mkDerivation {
  inherit src;

  pname = "find-tbb-cmake";
  version = "0.0.0";

  dontUnpack = true;
  skipBuild = true;

  installPhase = ''
    mkdir -p $out/lib/cmake
    cp ${src} $out/lib/cmake/FindTBB.cmake
  '';
}
