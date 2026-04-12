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
  version = "0.13.0-unstable-2026-04-10";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "9a93373b1830e94aed66d3994b5c65be40d0c07e";
    hash = "sha256-3Jc0fyJL0abD7meRlw/fhHwX5fwPB9RCIaE5Ur/u21I=";
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
