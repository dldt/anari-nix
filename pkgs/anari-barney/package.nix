{
  autoPatchelfHook,
  anari-sdk,
  barney,
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cudaPackages,
  nvidia-optix,
  openimagedenoise,
  python3,
  libGL,
  tbb,
}:
let
  src = fetchFromGitHub {
    owner = "ingowald";
    repo = "barney";
    branchName = "devel";
    rev = "c9d13c1b00fa142f1f81aebf9e95a50b9d7a059d";
    hash = "sha256-qsqiGaflWz6gz/0KUpIYLaYfEEeqZMMdMN34gVfd4uQ=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "anari-barney";
  version = "pynari-1.3.0-25-gc9d13c1";

  postPatch = ''
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
    autoPatchelfHook
    cmake
    cudaPackages.cuda_nvcc
    python3
  ];

  buildInputs = [
    anari-sdk
    barney

    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.libcurand
    nvidia-optix

    openimagedenoise
    libGL

    tbb
  ];

  postInstall = ''
    # in case it is installed. It is provided by the main barney package.
    rm  -f "''${out}/lib/libbarney.so"
  '';

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
