{
  boost,
  c-blosc,
  cmake,
  jemalloc,
  lib,
  openvdb,
  stdenv,
  tbb,
  zlib,

  libGL,
  libGLU,
  glfw,
  nix-update-script,
}:
stdenv.mkDerivation {
  inherit (openvdb) src version;

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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=skip"
    ];
  };

  meta = with lib; {
    description = "Open framework for voxel (NanoVDB tools)";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
