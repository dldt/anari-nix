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
  version = "v12.1.0";
  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "openvdb";
    rev = version;
    hash = "sha256-28vrIlruPl1tvw2JhjIAARtord45hqCqnA9UNnu4Z70=";
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

  cmakeFlags = with lib; [
    (cmakeBool "OPENVDB_BUILD_BINARIES" true)
    (cmakeBool "OPENVDB_BUILD_CORE" false)
    (cmakeBool "OPENVDB_BUILD_VDB_LOD" true)
    (cmakeBool "OPENVDB_BUILD_VDB_PRINT" false)
    (cmakeBool "OPENVDB_BUILD_VDB_RENDER" true)
    (cmakeBool "OPENVDB_BUILD_VDB_TOOL" true)
    (cmakeBool "OPENVDB_BUILD_VDB_VIEW" true)
  ];

  meta = with lib; {
    description = "Open framework for voxel (NanoVDB tools)";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
