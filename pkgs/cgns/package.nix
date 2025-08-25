{
  cmake,
  fetchFromGitHub,
  hdf5,
  hostPlatform,
  lib,
  libGL,
  libGLU,
  tcl,
  tk,
  stdenv,
  libSM,
  libXmu,
}:
let
  # Main source.
  version = "v4.5.0";
  src = fetchFromGitHub {
    owner = "CGNS";
    repo = "CGNS";
    rev = version;
    hash = "sha256-lPbXIC+O4hTtacxUcyNjZUWpEwo081MjEWhfIH3MWus=";
  };

  src_tk_private = fetchFromGitHub {
    name = "tk-private";
    owner = "tcltk";
    repo = "tk";
    rev = "core-${builtins.replaceStrings [ "." ] [ "-" ] tk.version}";
    # Protect the hash behind the version it has been built for
    # This way, when the our tk dependency version changes, our
    # hash will automatically invalidate.
    hash =
      if tk.version == "8.6.15" then
        "sha256-8UXJ9oJnvdUrZEn3dEoty+tOVOHMj1rbzN1oNoQInwo="
      else if tk.version == "8.6.16" then
        "sha256-iI8RNzpEALT+wE61Rs/nmqLqjlhNozmhSMVDIULivZo="
      else
        builtins.warn "Untested tk.version ${tk.version}" lib.fakeHash;
    postFetch = ''
      mkdir ''${out}/tk-private
      ln -s ../generic ''${out}/tk-private
    '';
  };
in
stdenv.mkDerivation {
  inherit version;

  pname = "cgns";

  inherit src;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    hdf5
    tcl
    tk
  ]
  ++ lib.optionals hostPlatform.isLinux [
    libGL
    libGLU
    libSM
    libXmu
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "CGNS_ENABLE_HDF5" true)
      (cmakeFeature "CMAKE_C_FLAGS" "-I${src_tk_private}")
      (cmakeFeature "CMAKE_CXX_FLAGS" "-I${src_tk_private}")
    ]
    ++ lib.optionals hostPlatform.isLinux (
      with lib;
      [
        (cmakeBool "CGNS_BUILD_CGNSTOOLS" true)
      ]
    );

  meta = with lib; {
    description = "The CFD General Notation System (CGNS) provides a standard for recording and recovering computer data associated with the numerical solution of fluid dynamics equations.";
    homepage = "https://cgns.org";
    license = licenses.zlib;
    platforms = platforms.unix;
  };
}
