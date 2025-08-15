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
  version = "v0.0.0-659-ga20137c";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "a20137cc47fbb3f45ee2e85fb5e53a1267a6143e";
    hash = "sha256-VFtR4nPty2jWGkW0XLkzLcw6GnqosEljhCYxBA7Z2S4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages_12_6.cuda_nvcc
  ];

  buildInputs = [
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
