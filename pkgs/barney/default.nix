{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cudaPackages,
  nvidia-optix,
  openimagedenoise,
  libGL,
  tbb_2021_11,
}:
let
  src = fetchFromGitHub {
    owner = "ingowald";
    repo = "barney";
    rev = "45877a0a3baa724cb3765821f56c889672eb9f77";
    hash = "sha256-ufX4Sghg7FaK5PeaaqAwX79O3MJUsmAnRHRSzIc2iVM=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "barney";
  version = "v0.9.10-4-g45877a0";

  patchPhase = ''
    echo Patching CMake files...
    for i in CMakeLists.txt barney/CMakeLists.txt anari/CMakeLists.txt
    do
        sed -e '/CUDA_USE_STATIC_CUDA_RUNTIME\s\+ON/{s/ON/OFF/;h};''${x;/./{x;q0};x;q1}' -i "''${i}"
    done
    echo done
  '';

  cmakeFlags = [
    "-DBARNEY_MPI=OFF"
    "-DBARNEY_BUILD_ANARI=OFF"
    "-DBARNEY_BACKEND_OPTIX=ON"
    "-DBARNEY_BACKEND_EMBREE=OFF"
    "-DCMAKE_CUDA_ARCHITECTURES=all-major"
  ];

  nativeBuildInputs = [
    cudaPackages.cuda_nvcc

    cmake
  ];

  propagatedBuildInputs = [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ];

  buildInputs = [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.libcurand
    nvidia-optix

    openimagedenoise
    libGL

    tbb_2021_11
  ];

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
