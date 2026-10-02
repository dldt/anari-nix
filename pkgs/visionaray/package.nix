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
  version = "0.7.0-unstable-2026-10-02";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "visionaray";
    rev = "b567865ef98072e027d4236bbc0811707e093b2b";
    hash = "sha256-4pcW7S4ZB44AtCo65JFUlDwqPf7v6r35slJKNgOkW1c=";
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
