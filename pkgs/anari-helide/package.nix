{
  anari-sdk,
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  embree,
  python3,
}:
let
  anari-sdk-src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "4598cac4058011b3f92ec7cc5d0fb229a5bfc00b";
    hash = "sha256-n3egrExfKRKKlFKp2DtoJJT0vP/1t3iouwSk1XOPeTA=";
  };
  embree_for_helide-src = fetchurl {
    url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip";
    hash = "sha256-Y9ZOWHlb3fbpxWT2aJVky4WHaU4CXn7HeQdyzIIYs7k=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide";
  version = "v0.14.1-23-g4598cac";

  # Main source
  src = anari-sdk-src // {
    outPath = anari-sdk-src.outPath + "/src/devices/helide";
  };

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

  meta = with lib; {
    description = "Helide device, embree based, for ANARI.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
