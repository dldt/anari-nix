{
  anari-sdk,
  autoPatchelfHook,
  barney,
  cmake,
  cudaPackages,
  fetchFromGitHub,
  glfw,
  lib,
  libGL,
  nix-update-script,
  nvidia-optix,
  openimagedenoise,
  python3,
  stdenv,
  tbb,
}:
stdenv.mkDerivation {
  pname = "anari-barney";
  version = "0-unstable-2025-11-13";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "barney";
    rev = "983d99b65a5f02f6f22454ebfb11e332e6b90651";
    hash = "sha256-2EzMruNyJf469kEwWlizDLM/+Yi4Ob6GDhT+SJaJTLE=";
    fetchSubmodules = true;
  };

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
    glfw

    tbb
  ];

  postInstall = ''
    # in case it is installed. It is provided by the main barney package.
    rm  -f "''${out}/lib/libbarney.so"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };
  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
