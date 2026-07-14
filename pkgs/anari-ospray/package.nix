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
  version = "0-unstable-2026-07-14";

  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "4835de78d37dda518c4aa20cedfd6d0d91c3b45e";
    hash = "sha256-Yk7qmyKaU43dMhcI/cPmVUOWF89ncHNH78FDz8zJLwA=";
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
