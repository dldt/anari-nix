{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages,
  anari-sdk,
  python3,
  visionaray,
  tbb,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "anari-visionaray";
  version = "0-unstable-2026-02-19";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "c8c7d12c3ece2283c3599fe56fc9f7f86757bb47";
    hash = "sha256-CAZT3TvGmPfzjHdBwjWBkFoaA34qjlzcPjon5lTgH34=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    visionaray
    tbb
  ]
  ++ lib.optionals cudaSupport [
    # CUDA and OptiX
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ];

  cmakeFlags = with lib; [
    (cmakeBool "ANARI_VISIONARAY_ENABLE_CUDA" cudaSupport)
    (cmakeBool "ANARI_VISIONARAY_ENABLE_NANOVDB" true)
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library, exposed through ANARI.";
    homepage = "https://github.com/szellmann/anari-visionaray";
    license = licenses.bsd3;
    platforms = platforms.unix;
    broken = stdenv.hostPlatform.system == "aarch64-linux" && cudaSupport;
  };
}
