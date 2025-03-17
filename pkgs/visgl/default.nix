{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  libGL,
  pkg-config,
  python3,
}:
stdenv.mkDerivation {
  pname = "visgl";
  version = "v0.10.1-74-gc0956ab";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "c0956ab699565274848d34f469235f4e25ae21a8";
    hash = "sha256-/mwDPyKBlTLVY89KYwEM4LbAMWh2NJsN5q3g1A06l5E=";
  };

  cmakeFlags = [
    "-DVISRTX_BUILD_RTX_DEVICE=OFF"
    "-DVISRTX_BUILD_GL_DEVICE=ON"
    "-DVISRTX_PRECOMPILE_SHADERS=OFF"
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

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
