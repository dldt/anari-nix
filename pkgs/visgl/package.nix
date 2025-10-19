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
  version = "v0.12.0-236-g4656a25";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "4656a254b674839a13b0ae58ab95d243d9237338";
    hash = "sha256-WNQgKndiUeGn1i4lbh38t2r9YwtXLXH7zFgtt9sUczQ=";
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
