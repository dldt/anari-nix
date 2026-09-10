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
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "visionaray";
  version = "0.7.0-unstable-2026-09-09";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "visionaray";
    rev = "4418d9b6b778296bc16f4d5b3fa1060c50199f5f";
    hash = "sha256-LtTX5h+tneInBbxBfwz//bpiOmxA96de47Hh/FnZpVE=";
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library.";
    homepage = "https://vis.uni-koeln.de/forschung/software-visionaray";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
