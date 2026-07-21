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
  version = "0-unstable-2026-07-29";

  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "b0766780ddd0c13ba6c8a3453494d0114cba5a7d";
    hash = "sha256-yStsPZw/gWnAPDq7b0eCjWgKL7C00YfAJVEEoHnsh44=";
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
