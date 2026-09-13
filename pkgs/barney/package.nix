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
  version = "0-unstable-2026-09-11";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "barney";
    rev = "2d57d0caa672596f4da917609de5253af85baa78";
    hash = "sha256-c7a4Cj6gDE4dXsvvpAlR/IpmD4b3p3QGaJ3fb8p9OeM=";
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
