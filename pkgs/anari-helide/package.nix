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
  version = "0.16.0-unstable-2026-11-06";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "62f5007711f8ed5c0c8f1307c3717b581b4611ec";
    hash = "sha256-b3cBU/S+2S/+pkEbzC8tQgpF6XguuuBh8LtRTO5ejYM=";
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
