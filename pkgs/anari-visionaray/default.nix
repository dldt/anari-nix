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
  version = "v0.0.0-567-gaef2546";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "aef25461a06c179cb0738130ec66b51f9bf26c10";
    hash = "sha256-ONc8ByO/jEpoNLjjaOND7Lawz2dLuuv5Ns4Dljme0Tc=";
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
