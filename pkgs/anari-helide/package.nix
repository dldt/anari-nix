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
  version = "0.16.0-unstable-2026-10-31";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "467eaabc5180e760d218c7d8d0aa02048e4863d9";
    hash = "sha256-S9tsVU0VDJB7xz3H7kaU+OoWRChlFyJnnoajBSfsCQ4=";
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
