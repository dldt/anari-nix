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
  version = "v0.12.0-279-g1faeab3";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "1faeab38f5b0bc592df8bfabdd0fcbd7eb70c75e";
    hash = "sha256-dYLFH2QBOOUNtRFPL+WCKy1wWhLN1rHY89Pi5T+e+yg=";
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

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
