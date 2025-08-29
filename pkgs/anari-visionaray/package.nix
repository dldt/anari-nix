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
  tbb,
  find-tbb-cmake,
}:
stdenv.mkDerivation {
  pname = "anari-visionaray";
  version = "v0.0.0-673-g13c782f";

  # Main source.
  src = fetchFromGitHub {
    owner = "szellmann";
    repo = "anari-visionaray";
    rev = "13c782f3eec8e1dd53075fc4ef11ca7b2897be93";
    hash = "sha256-9428scWUX5BZ8gz2MDjqjc0bbZD4CWR3Oq4jma3dsbk=";
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
    tbb
    find-tbb-cmake
  ]
  ++ lib.optionals cudaSupport [
    # CUDA and OptiX
    cudaPackages_12_6.cuda_cudart
    cudaPackages_12_6.cuda_cccl
  ];

  cmakeFlags = with lib; [
    (cmakeBool "ANARI_VISIONARAY_ENABLE_CUDA" cudaSupport)
    (cmakeBool "ANARI_VISIONARAY_ENABLE_NANOVDB" true)
    (cmakeFeature "CMAKE_MODULE_PATH" "${find-tbb-cmake}/lib/cmake")
  ];

  meta = with lib; {
    description = "A C++ based, cross platform ray tracing library, exposed through ANARI.";
    homepage = "https://github.com/szellmann/anari-visionaray";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
