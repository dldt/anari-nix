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
  version = "v12.0.0";
  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "openvdb";
    rev = version;
    hash = "sha256-S2uvzDCrTxAmvUMJr5PChcYTqhIHvRZbOfQLtUvzypI=";
  };
in
stdenv.mkDerivation {
  inherit src version;

  pname = "nanovdb-tools";

  patches = [
    (fetchpatch {
      url = "https://github.com/AcademySoftwareFoundation/openvdb/commit/930c3acb8e0c7c2f1373f3a70dc197f5d04dfe74.diff";
      hash = "sha256-EjwSw1GZ6WgTlA4GNzOfaB/9jOGJkGBQ/5V6lOEoji8=";
    })
  ];

  nativeBuildInputs =
    [
      cmake
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages.cuda_nvcc
    ];

  buildInputs =
    [
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
    [
      "-DNANOVDB_BUILD_TOOLS=ON"
      "-DNANOVDB_USE_OPENVDB=ON"
      "-DOPENVDB_BUILD_BINARIES=ON"
      "-DOPENVDB_BUILD_CORE=OFF"
      "-DOPENVDB_BUILD_VDB_PRINT=OFF"
      "-DUSE_NANOVDB=ON"
    ]
    ++ lib.optionals cudaSupport [
      "-DNANOVDB_USE_CUDA=ON"
    ];

  meta = with lib; {
    description = "Open framework for voxel (NanoVDB tools)";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
