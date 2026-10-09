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
  opencolorio,
  openimagedenoise,
  openimageio,
  openvdb,
  openexr,
  openjpeg,
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
  version = "0-unstable-2026-10-08";

  src = fetchFromGitHub {
    owner = "jeffamstutz";
    repo = "anari-cycles";
    rev = "eebf0eeb549ab4fabfd967ebe3bd0deb0e081279";
    hash = "sha256-IKG99IsRKItqBMQ4zGBs7SNEZ/iYH670lwxlUhApLHc=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-Link-with-openvdb-when-needed.patch
    ./0002-Hardcode-Cycles-root-folder-to-CMAKE_INSTALL_PREFIX.patch
    ./0003-Link-with-IOKit-on-when-building-Metal.patch
    ./0004-Do-not-build-cycles-standalone-app.patch
    ./0005-Revert-Build-Use-CMAKE_CURRENT_SOURCE_DIR-for-findin.patch
    ./0006-Enable-SSE2NEON-for-the-ANARI-device-library.patch
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
    opencolorio
    openimagedenoise
    openimageio
    openjpeg
    openvdb
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
      # OSL on OptiX needs an OSL built with OSL_USE_OPTIX (CUDA shadeops
      # bitcode); nixpkgs' OSL lacks it and the JIT asserts at render time.
      (cmakeBool "WITH_CYCLES_OSL" false)
      # anari-cycles forces WITH_CYCLES_DEVICE_{CUDA,OPTIX,OPENIMAGEDENOISE}
      # from these ANARI_CYCLES_USE_* options (CACHE ... FORCE), overriding
      # any -D passed directly for those; also gates the WITH_OPTIX /
      # WITH_OPENIMAGEDENOISE defines the ANARI device needs to compile in
      # denoiser support.
      (cmakeBool "ANARI_CYCLES_USE_OIDN" true)
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
        (cmakeBool "WITH_CUDA_DYNLOAD" false)

        # New CUDA setup in Nixpkgs prevents FindCUDA from working correctly
        (cmakeFeature "CMAKE_PREFIX_PATH" (cudaPackages.cuda_cudart + "/lib/stubs"))
      ]
    )
    ++ lib.optionals optixSupport (
      with lib;
      [
        (cmakeBool "ANARI_CYCLES_USE_OPTIX" true)
        # Avoid FetchOptiXHeaders.cmake reaching the network in the sandbox.
        (cmakeFeature "OPTIX_ROOT_DIR" (toString nvidia-optix8))
        (cmakeFeature "CYCLES_RUNTIME_OPTIX_ROOT_DIR" (toString nvidia-optix8))
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
