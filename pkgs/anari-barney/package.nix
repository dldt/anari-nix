{
  anari-sdk,
  barney,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
  embreeSupport ? !cudaSupport,
  cudaPackages,
  fetchFromGitHub,
  lib,
  nix-update-script,
  nvidia-optix,
  embree,
  python3,
  stdenv,
  tbb,
  openimagedenoise,
}:
stdenv.mkDerivation {
  pname = "anari-barney";
  version = "0-unstable-2025-12-10";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "barney";
    rev = "b5ad9de8aaa34c64efcce0f6d639683707bfb7aa";
    hash = "sha256-cvMNjoDn0pfM5J23P6T5Jjyzhs9fYqrZ598xzVMuAhA=";
    fetchSubmodules = true;
  };

  postPatch = ''
    echo Patching CMake files...
    for i in CMakeLists.txt barney/CMakeLists.txt anari/CMakeLists.txt
    do
        sed -e '/CUDA_USE_STATIC_CUDA_RUNTIME\s\+ON/{s/ON/OFF/;h};''${x;/./{x;q0};x;q1}' -i "''${i}"
    done
    echo done
  '';

  cmakeFlags = with lib; [
    (cmakeBool "BARNEY_MPI" false)
    (cmakeBool "BARNEY_BUILD_ANARI" true)
    (cmakeBool "BARNEY_BACKEND_OPTIX" optixSupport)
    (cmakeBool "BARNEY_BACKEND_EMBREE" embreeSupport)
    (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
  ];

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    barney
    tbb
    openimagedenoise
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

  postInstall = ''
    # in case it is installed. It is provided by the main barney package.
    rm  -f "''${out}/lib/libbarney.so"
  '';

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
    platforms = lib.platforms.all;
  };
}
