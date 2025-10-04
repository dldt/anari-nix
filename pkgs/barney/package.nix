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
    rev = "9c1e47ce4f0fa9cb6b2de67130920bba79c32816";
    hash = "sha256-iQSjDLW50H2Vd3sQPcPtJuitEpsyiZ1FLdK1n0teuH4=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "barney";
  version = "pynari-1.3.0-42-g9c1e47c";

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
