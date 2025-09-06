{
  lib,
  stdenv,
  fetchFromGitHub,
  apple-sdk_13,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? config.cudaSupport,
  cudaPackages,
  nvidia-optix8,
  anari-sdk,
  libjpeg,
  libpng,
  libtiff,
  libGL,
  python3,
  openimageio,
  openvdb,
  openexr,
  openjpeg,
  osl,
  sse2neon,
  tbb,
  pugixml,
  zlib,
  zstd,
}:
assert lib.assertMsg (!optixSupport || cudaSupport) "OptiX support requires CUDA support";
stdenv.mkDerivation {

  pname = "anari-cycles";
  version = "v0.0.0-37-gb49b4ef";

  src = fetchFromGitHub {
    owner = "jeffamstutz";
    repo = "anari-cycles";
    rev = "b49b4ef9b639d8ac183b4a0194d2dc6b75771788";
    hash = "sha256-1XCB9jtdEPZLZIs03Ief6MzFsASbENOV01mdKf5KAkw=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-Link-with-openvdb-and-osl-when-needed.patch
    ./0002-Hardcode-Cycles-root-folder-to-CMAKE_INSTALL_PREFIX.patch
    ./0003-Link-with-IOKit-on-when-building-Metal.patch
    ./0004-Do-not-build-cycles-standalone-app.patch
    ./0005-Revert-Build-Use-CMAKE_CURRENT_SOURCE_DIR-for-findin.patch
    ./0006-Fix-compilation-using-TypeFloat-and-other-TypeDescs.patch
  ];

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    libjpeg
    libpng
    libtiff
    openexr
    openimageio
    openjpeg
    openvdb
    osl
    pugixml
    pugixml
    tbb
    zlib
    zstd
  ]
  ++ lib.optionals stdenv.isDarwin [
    apple-sdk_13
    sse2neon
  ]
  ++ lib.optionals cudaSupport [
    # CUDA and OptiX
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    libGL
  ]
  ++ lib.optionals optixSupport [
    nvidia-optix8
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "WITH_CYCLES_DEVICE_HIP" false)
      (cmakeBool "WITH_CYCLES_NANOVDB" true)
      (cmakeBool "WITH_CYCLES_OPENVDB" true)
      (cmakeBool "WITH_CYCLES_OSL" true)
    ]
    ++ lib.optionals stdenv.isDarwin (
      with lib;
      [
        (cmakeBool "WITH_CYCLES_DEVICE_METAL" true)
        (cmakeFeature "SSE2NEON_INCLUDE_DIR" "${lib.getDev sse2neon}/lib")
      ]
    )
    ++ lib.optionals cudaSupport (
      with lib;
      [
        (cmakeBool "WITH_CYCLES_DEVICE_CUDA" true)
        (cmakeBool "WITH_CUDA_DYNLOAD" false)
        (cmakeBool "WITH_CYCLES_CUDA_BINARIES" true)
      ]
    )
    ++ lib.optionals optixSupport (
      with lib;
      [
        (cmakeBool "WITH_CYCLES_DEVICE_OPTIX" true)
        (cmakeFeature "CYCLES_RUNTIME_OPTIX_ROOT_DIR" (builtins.toString nvidia-optix8))
      ]
    );

  installPhase = ''
    cmake --build device --target install
    cmake --build cycles --target install
  '';

  meta = with lib; {
    description = "Blender Cycles, exposed through ANARI.";
    homepage = "https://github.com/jeffamstutz/anari-cycles";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
