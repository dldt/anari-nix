{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  libGL,
  pkg-config,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "visgl";
  version = "0.13.0-unstable-2026-04-25";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "6be0238a90b25a2a16d335ad9f173ebb6457ad9b";
    hash = "sha256-mUmuFX8/e1EZZHdLDv3/APDy3z4Ss20AsO1l1Kr8iW0=";
  };

  cmakeFlags = with lib; [
    (cmakeBool "VISRTX_BUILD_RTX_DEVICE" false)
    (cmakeBool "VISRTX_BUILD_GL_DEVICE" true)
    (cmakeBool "VISRTX_PRECOMPILE_SHADERS" false)
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    anari-sdk
    libGL
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
