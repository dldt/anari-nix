{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cudaPackages,
  nvidia-optix,
  openimagedenoise,
  libGL,
  tbb,
}:
let
  src = fetchFromGitHub {
    owner = "ingowald";
    repo = "barney";
    branchName = "devel";
    rev = "8d45449bfedc33cb283f2ab6601b59b9c431675e";
    hash = "sha256-wlaY2/Ufpisb/ARjq/0J1aJJ16k0ihszGnBxi4HTW2s=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "barney";
  version = "v0.10.0-21-g8d45449";

  patchPhase = ''
    echo Patching CMake files...
    for i in CMakeLists.txt barney/CMakeLists.txt anari/CMakeLists.txt
    do
        sed -e '/CUDA_USE_STATIC_CUDA_RUNTIME\s\+ON/{s/ON/OFF/;h};''${x;/./{x;q0};x;q1}' -i "''${i}"
    done
    echo done
  '';

  cmakeFlags = with lib; [
    (cmakeBool "BARNEY_MPI" false)
    (cmakeBool "BARNEY_BUILD_ANARI" false)
    (cmakeBool "BARNEY_BACKEND_OPTIX" true)
    (cmakeBool "BARNEY_BACKEND_EMBREE" false)
    (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
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

    tbb
  ];

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
