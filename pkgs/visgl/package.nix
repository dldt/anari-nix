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
  version = "tsd_removed-unstable-2026-09-16";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "d5e2ce66f4c0cc851657adf333dc839ccb7effb5";
    hash = "sha256-xWZHvO5zb1Ei6MSfRYP7dgPqKxtxRjZ0J07WExxu1zU=";
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
