{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  spirv-headers,
  directx-shader-compiler,
  cmakeCurses,
}:
let
  version = "v4.14.1";
  src = fetchFromGitHub {
    owner = "NVIDIA-RTX";
    repo = "NRD";
    rev = version;
    hash = "sha256-Zqvb1q9cSGHBdvio5BXuoahlaG/xhigTeppy3ozsCFo=";
    fetchSubmodules = true;
  };

  mathlib_src = fetchFromGitHub {
    name = "mathlib-src";
    owner = "NVIDIA-RTX";
    repo = "MathLib";
    rev = "ce3142d54f5ab523bb39c184d905ad9786af0620";
    hash = "sha256-UCfj+7b/KRtjG2IpPAgtczbZrgkTixMQnhcorFbV+uM=";
  };

  shadermake_src = fetchFromGitHub {
    name = "shadermake-src";
    owner = "NVIDIA-RTX";
    repo = "ShaderMake";
    rev = "66a89a4beed48e994008ffca33bfdae8244e288a";
    hash = "sha256-qbTEJz+UDstYzLbnCeQLtp6WGpxaVnw6iD6UCwbSPvg=";
  };
in
stdenv.mkDerivation {
  inherit src version;
  pname = "nrd";

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_BASE_DIR=/build/"
  ];

  nativeBuildInputs = [
    cmake
    cmakeCurses
  ];

  buildInputs = [
    spirv-headers
    directx-shader-compiler
  ];

  sourceRoot = "source";

  srcs = [
    src
    mathlib_src
    shadermake_src
  ];

  installPhase = ''
    mkdir -p $out/{include/NRD/shader,lib}
    cp -r ${src}/Include $out/include/NRD/
    cp -r ${src}/Shaders/Include/ $out/include/NRD/shaders/
    cp libNRD.so $out/lib/
  '';

  meta = with lib; {
    description = "NVIDIA Real-Time Denoisers (NRD) is a spatio-temporal API agnostic denoising library.";
    homepage = "https://github.com/NVIDIAGameWorks/RayTracingDenoiser";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
