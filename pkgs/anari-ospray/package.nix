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
  version = "0-unstable-2026-05-12";

  # Main source. Tracks jeffamstutz/anari-ospray (jda/dev), which is ahead of
  # the lagging ospray/anari-ospray upstream.
  src = fetchFromGitHub {
    owner = "jeffamstutz";
    repo = "anari-ospray";
    rev = "df6088f27b9c5560a4b2a7707eefe37f166eb402";
    hash = "sha256-YW9BlQUKfQBtG0KZQelVh9z0u3j9aRK2TmKSkXIalmM=";
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
      "--version=branch=jda/dev"
    ];
  };

  meta = with lib; {
    description = "Translation layer from Khronos ANARI to Intel OSPRay: ANARILibrary and ANARIDevice 'ospray'.";
    homepage = "https://github.com/ospray/anari-ospray";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
