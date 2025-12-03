{
  lib,
  stdenv,
  fetchFromGitHub,
  apple-sdk_14,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
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
  nix-update-script,
}:
assert lib.assertMsg (!optixSupport || cudaSupport) "OptiX support requires CUDA support";
stdenv.mkDerivation {

  pname = "anari-cycles";
  version = "0-unstable-2025-10-10";

  src = fetchFromGitHub {
    owner = "jeffamstutz";
    repo = "anari-cycles";
    rev = "1db3ffac8c740921aff2636936fd9fa415d64dc6";
    hash = "sha256-aytrYzpIuBW+Gq3u7CXOI+ivxH465eKUJMWx2Z+fbPQ=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-Link-with-openvdb-and-osl-when-needed.patch
    ./0002-Hardcode-Cycles-root-folder-to-CMAKE_INSTALL_PREFIX.patch
    ./0003-Link-with-IOKit-on-when-building-Metal.patch
    ./0004-Do-not-build-cycles-standalone-app.patch
    ./0005-Revert-Build-Use-CMAKE_CURRENT_SOURCE_DIR-for-findin.patch
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
    apple-sdk_14
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

        # New CUDA setup in Nixpkgs prevents FindCUDA from working correctly
        (cmakeFeature "CMAKE_PREFIX_PATH" (cudaPackages.cuda_cudart + "/lib/stubs"))
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Blender Cycles, exposed through ANARI.";
    homepage = "https://github.com/jeffamstutz/anari-cycles";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
