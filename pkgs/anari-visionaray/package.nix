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
  version = "0-unstable-2026-07-08";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "594ffb15eb1ab8663ed0bfd4f12589dc92a4bce5";
    hash = "sha256-dHycW/RvHvMcomMgm0xp5snc8KITo0zL+K08w+SM0Qw=";
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
