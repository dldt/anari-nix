{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cudaPackages_12_6,
  anari-sdk,
  python3,
  visionaray,
}:
stdenv.mkDerivation {
  pname = "anari-visionaray";
  version = "v0.0.0-564-gd1c3ae8";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "d1c3ae8674eb8a951b335a12e3a47e6d2a7cc8db";
    hash = "sha256-6V5j4jpUDFcH6iZyyu93ibSOtQfxy79/N2UIy71+0OA=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cudaPackages_12_6.cuda_nvcc

    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    visionaray

    # CUDA and OptiX
    cudaPackages_12_6.cuda_cudart
    cudaPackages_12_6.cuda_cccl
  ];

  cmakeFlags = [
    "-DANARI_VISIONARAY_ENABLE_CUDA=ON"
    "-DANARI_VISIONARAY_ENABLE_NANOVDB=ON"
  ];

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library, exposed through ANARI.";
    homepage = "https://github.com/szellmann/anari-visionaray";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
