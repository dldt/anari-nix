{
  boost,
  config,
  cudaPackages,
  cudaSupport ? config.cudaSupport,
  c-blosc,
  cmake,
  fetchFromGitHub,
  jemalloc,
  lib,
  openvdb,
  stdenv,
  tbb,
  zlib,
}:
let
  # Main source.
  version = "v12.1.1";
  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "openvdb";
    rev = version;
    hash = "sha256-FYXySDWceby/oLdNDMqzrR1sR5OF0T5u+j2qJH5cBMQ=";
  };
in
stdenv.mkDerivation {
  inherit src version;

  pname = "nanovdb-tools";

  patches = [
    ./0001-Find-CCCL-from-nix-instead-getting-it-from-github.patch
  ];

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    boost
    c-blosc
    jemalloc
    openvdb
    tbb
    zlib
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.nccl
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "NANOVDB_BUILD_TOOLS" true)
      (cmakeBool "NANOVDB_USE_OPENVDB" true)
      (cmakeBool "OPENVDB_BUILD_BINARIES" true)
      (cmakeBool "OPENVDB_BUILD_CORE" false)
      (cmakeBool "OPENVDB_BUILD_VDB_PRINT" false)
      (cmakeBool "USE_NANOVDB" true)
    ]
    ++ lib.optionals cudaSupport (
      with lib;
      [
        (cmakeBool "NANOVDB_USE_CUDA" true)
      ]
    );

  meta = with lib; {
    description = "Open framework for voxel (NanoVDB tools)";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
