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
  nvidia-optix,
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
  tbb_2021,
  pugixml,
  zlib,
}:
assert lib.assertMsg (!optixSupport || cudaSupport) "OptiX support requires CUDA support";
stdenv.mkDerivation {

  pname = "anari-cycles";
  version = "v0.0.0-29-gb4e8a77";

  src = fetchFromGitHub {
    owner = "jeffamstutz";
    repo = "anari-cycles";
    rev = "b4e8a770c1aa63cfc539b6bfcf50f2e4ed3dcd08";
    hash = "sha256-88oMngIpQ8wBnwZJBSTZDPv88OYGzQirc288U/Q13zQ=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-Link-with-openvdb-and-osl-when-needed.patch
    ./0002-Hardcode-Cycles-root-folder-to-CMAKE_INSTALL_PREFIX.patch
    ./0003-Link-with-IOKit-on-when-building-Metal.patch
    ./0004-Fix-compilation-using-TypeFloat-and-other-TypeDescs.patch
    ./0005-Do-not-build-cycles-standalone-app.patch
  ];

  nativeBuildInputs =
    [
      cmake
      python3
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages.cuda_nvcc
    ];

  buildInputs =
    [
      anari-sdk
      libjpeg
      openimageio
      openjpeg
      pugixml
      libtiff
      openexr
      openvdb
      osl
      libpng
      zlib
      tbb_2021
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
      nvidia-optix
    ];

  cmakeFlags =
    [
      "-DWITH_CYCLES_DEVICE_HIP=OFF"
      "-DWITH_CYCLES_NANOVDB=ON"
      "-DWITH_CYCLES_OPENVDB=ON"
      "-DWITH_CYCLES_OSL=ON"
    ]
    ++ lib.optionals stdenv.isDarwin [
      "-DWITH_CYCLES_DEVICE_METAL=ON"
      "-DSSE2NEON_INCLUDE_DIR=${lib.getDev sse2neon}/lib"
    ]
    ++ lib.optionals cudaSupport [
      "-DWITH_CYCLES_DEVICE_CUDA=ON"
      "-DWITH_CUDA_DYNLOAD=OFF"
      "-DWITH_CYCLES_CUDA_BINARIES=ON"
    ]
    ++ lib.optionals optixSupport [
      "-DWITH_CYCLES_DEVICE_OPTIX=ON"
      "-DCYCLES_RUNTIME_OPTIX_ROOT_DIR=${nvidia-optix}"
    ];

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
