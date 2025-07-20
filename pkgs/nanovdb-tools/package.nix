{
  boost,
  config,
  cudaPackages,
  cudaSupport ? config.cudaSupport,
  c-blosc,
  cmake,
  fetchFromGitHub,
  fetchpatch,
  jemalloc,
  lib,
  openvdb,
  stdenv,
  tbb,
  zlib,
}:
let
  # Main source.
  version = "v12.0.1";
  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "openvdb";
    rev = version;
    hash = "sha256-ofVhwULBDzjA+bfhkW12tgTMnFB/Mku2P2jDm74rutY=";
  };
in
stdenv.mkDerivation {
  inherit src version;

  pname = "nanovdb-tools";

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
