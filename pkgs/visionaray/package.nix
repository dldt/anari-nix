{
  boost,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages,
  fetchFromGitHub,
  freeglut,
  lib,
  libjpeg,
  libpng,
  libtiff,
  openexr,
  ptex,
  stdenv,
  tbb,
}:
stdenv.mkDerivation {
  pname = "visionaray";
  version = "v0.6.1-1-g702d057";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "visionaray";
    rev = "702d05767477a6a109b84dca7ccc6ee16deab01a";
    hash = "sha256-ieU4Y8qMNeZjXhx3ktXQGNUzPR5XY4yJnNxqyl2wx/8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    boost
    tbb
    freeglut
    libjpeg
    libpng
    libtiff
    openexr
    ptex
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cccl
    cudaPackages.cuda_cudart
  ];

  postUnpack = ''
    substituteInPlace \
      source/src/3rdparty/pbrt-parser/pbrtParser/impl/syntactic/FileMapping.h \
      --replace-fail "#include <string>" "#include <cstdint>\n#include <string>"
  '';

  postInstall = ''
    rm -fr ''${out}/lib/cmake/pbrtParser
  '';

  cmakeFlags = with lib; [
    (cmakeBool "VSNRAY_ENABLE_PBRT_PARSER" true)
    (cmakeBool "VSNRAY_ENABLE_PTEX" true)
    (cmakeBool "VSNRAY_ENABLE_TBB" true)
    (cmakeBool "VSNRAY_ENABLE_EXAMPLES" false)
    (cmakeBool "VSNRAY_ENABLE_VIEWER" false)
    (cmakeBool "VSNRAY_ENABLE_COMMON" false)
    (cmakeBool "VSNRAY_ENABLE_CUDA" cudaSupport)
  ];

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library.";
    homepage = "https://vis.uni-koeln.de/forschung/software-visionaray";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
