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
  tbb_2021,
}:
let
  src = fetchFromGitHub {
    owner = "ingowald";
    repo = "barney";
    branchName = "devel";
    rev = "45877a0a3baa724cb3765821f56c889672eb9f77";
    hash = "sha256-ufX4Sghg7FaK5PeaaqAwX79O3MJUsmAnRHRSzIc2iVM=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "anari-barney";
  version = "v0.9.10-4-g45877a0";

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

    tbb_2021
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
