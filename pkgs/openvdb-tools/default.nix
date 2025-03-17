{
  boost,
  c-blosc,
  cmake,
  fetchFromGitHub,
  jemalloc,
  lib,
  openvdb,
  stdenv,
  tbb,
  zlib,

  libGL,
  libGLU,
  glfw,
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

  pname = "openvdb-tools";

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    libGL
    libGLU
    glfw

    boost
    c-blosc
    jemalloc
    openvdb
    tbb
    zlib
  ];

  cmakeFlags = [
    "-DOPENVDB_BUILD_BINARIES=ON"
    "-DOPENVDB_BUILD_CORE=OFF"
    "-DOPENVDB_BUILD_VDB_LOD=ON"
    "-DOPENVDB_BUILD_VDB_PRINT=OFF"
    "-DOPENVDB_BUILD_VDB_RENDER=ON"
    "-DOPENVDB_BUILD_VDB_TOOL=ON"
    "-DOPENVDB_BUILD_VDB_VIEW=ON"
  ];

  meta = with lib; {
    description = "Open framework for voxel (NanoVDB tools)";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
