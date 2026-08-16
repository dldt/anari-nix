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
  version = "0-unstable-2026-08-15";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "c028aa80adf56f6debc7590d2c6c874e0a8c8365";
    hash = "sha256-kLb5waAyT9BEd6Jnm0fo6HJ0cyrQOMHiW4kf7loHNUg=";
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
