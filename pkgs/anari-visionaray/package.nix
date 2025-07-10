{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages_12_6,
  anari-sdk,
  python3,
  visionaray,
}:
stdenv.mkDerivation {
  pname = "anari-visionaray";
  version = "v0.0.0-627-g20852a8";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "20852a814bc019306ce6823cd52e68361a45eec5";
    hash = "sha256-YyCfRUqCUYEGWT9qkfJzRK9VfCrU5dAb10qcsuEFzZo=";
    fetchSubmodules = true;
  };

  nativeBuildInputs =
    [
      cmake
      python3
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages_12_6.cuda_nvcc
    ];

  buildInputs =
    [
      anari-sdk
      visionaray
    ]
    ++ lib.optionals cudaSupport [
      # CUDA and OptiX
      cudaPackages_12_6.cuda_cudart
      cudaPackages_12_6.cuda_cccl
    ];

  cmakeFlags = with lib; [
    (cmakeBool "ANARI_VISIONARAY_ENABLE_CUDA" cudaSupport)
    (cmakeBool "ANARI_VISIONARAY_ENABLE_NANOVDB" true)
  ];

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library, exposed through ANARI.";
    homepage = "https://github.com/szellmann/anari-visionaray";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
