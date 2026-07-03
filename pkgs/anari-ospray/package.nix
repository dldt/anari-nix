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
  version = "0-unstable-2026-06-24";

  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "479a5e3079210744ba653792d3d68b71c073857c";
    hash = "sha256-OO9jciaQ2f+uk6LFghdVy5ncgHfEhzB50KPBnO3VjbQ=";
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
