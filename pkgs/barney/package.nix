{
  lib,
  stdenv,
  fetchFromGitHub,
  anari-sdk,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
  embreeSupport ? !cudaSupport,
  cudaPackages,
  nvidia-optix,
  nix-update-script,
  openimagedenoise,
  python3,
  tbb,
  embree,
}:
stdenv.mkDerivation {
  pname = "barney";
  version = "0-unstable-2026-10-03";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "barney";
    rev = "824e4a3ee7b0f4888b619004ac0feaa63b4727ca";
    hash = "sha256-vxQV9df1p7W+RVxZZGkGZb+RxK5k9OCS+unerYodVj8=";
    fetchSubmodules = true;
  };

  cmakeFlags =
    with lib;
    [
      (cmakeBool "BARNEY_MPI" false)
      (cmakeBool "BARNEY_BACKEND_CPU" embreeSupport)
      (cmakeBool "BARNEY_BACKEND_CUDA" (cudaSupport && !optixSupport))
      (cmakeBool "BARNEY_BACKEND_OPTIX" optixSupport)
    ]
    ++ (lib.optionals cudaSupport [
      (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
    ]);

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
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
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
