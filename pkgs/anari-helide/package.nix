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
    url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.4.1.zip";
    hash = "sha256-ZDuHSQsgdHWHKwchAZ6+OUf+uRBPNsJXlUVVFuToW4I=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide";
  version = "0.17.0-1-unstable-2026-11-25";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "bbd28df094a209a7765d476c19a7d2dfabc95209";
    hash = "sha256-T5XQu+cUDBkNEATdqdd+5/hB3pYIOukrkASLKuJCF7I=";
  };
  sourceRoot = "source/src/devices/helide";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_embree/"
    cp "${embree_for_helide-src}" "''${sourceRoot}/.anari_deps/anari_embree/v4.4.1.zip"
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
