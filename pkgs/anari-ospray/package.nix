{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  python3,
  embree-ispc,
  ospray,
  # openvkl,
  # rkcommon,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "anari-ospray";
  version = "0-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "549dfd9422d468b2768da08cb9abad4d433eb4c0";
    hash = "sha256-GjFBgRAv90bNhZsXYyVjhIAAWW+W3uZ+qW8Be2lLPgQ=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    embree-ispc
    ospray
    # openvkl
    # rkcommon
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch=main"
    ];
  };

  meta = with lib; {
    description = "Translation layer from Khronos ANARI to Intel OSPRay: ANARILibrary and ANARIDevice 'ospray'.";
    homepage = "https://github.com/ospray/anari-ospray";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
