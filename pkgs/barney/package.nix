{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
  embreeSupport ? !cudaSupport,
  cudaPackages,
  nvidia-optix,
  nix-update-script,
  openimagedenoise,
  tbb,
  embree,
}:
stdenv.mkDerivation {
  pname = "barney";
  version = "0-unstable-2026-02-11";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "barney";
    rev = "1af11293e90007e3488cfcb3c984d43aae692564";
    hash = "sha256-JiD7Z8Y9Fy+z46iVB3rVe2OXZpEAPowuG+NkC8rX+kg=";
    fetchSubmodules = true;
  };

  patches = [
    ./fix-include-install-path.patch
  ];

  patchFlags = [ "-p1" ];

  postPatch = ''
    echo Patching CMake files...
    for i in CMakeLists.txt barney/CMakeLists.txt anari/CMakeLists.txt
    do
        sed -e '/CUDA_USE_STATIC_CUDA_RUNTIME\s\+ON/{s/ON/OFF/;h};''${x;/./{x;q0};x;q1}' -i "''${i}"
    done
    echo done
  '';

  cmakeFlags =
    with lib;
    [
      (cmakeBool "BARNEY_MPI" false)
      (cmakeBool "BARNEY_BUILD_ANARI" false)
      (cmakeBool "BARNEY_BACKEND_OPTIX" optixSupport)
      (cmakeBool "BARNEY_BACKEND_EMBREE" embreeSupport)
    ]
    ++ (lib.optionals cudaSupport [
      (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
    ]);

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    openimagedenoise
    tbb
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.libcurand
  ]
  ++ lib.optionals optixSupport [
    nvidia-optix
  ]
  ++ lib.optionals embreeSupport [
    embree
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "A Multi-GPU (and optionally, Multi-Node) Implementation of the ANARI Rendering API";
    homepage = "https://github.com/NVIDIA/barney";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
