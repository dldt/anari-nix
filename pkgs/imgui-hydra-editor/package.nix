{
  alembic,
  cmake,
  draco,
  embree,
  fetchFromGitHub,
  imath,
  lib,
  libGL,
  openimageio,
  opensubdiv,
  openusd,
  osl,
  stdenv,
  tbb,
  xorg,
}:
let
  version = "v3.0.0";
in
stdenv.mkDerivation {
  inherit version;
  pname = "imgui-hydra-editor";

  # Main source.
  src = fetchFromGitHub {
    owner = "raph080";
    repo = "ImGuiHydraEditor";
    rev = version;
    hash = "sha256-8OxJ2gfPo0T/rOYMIik/Uk2dRFtQZav99/6e41SJUBk=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    alembic
    draco
    embree
    imath
    libGL
    openimageio
    opensubdiv
    openusd
    osl
    tbb
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXt
  ];

  postUnpack = ''
        substituteInPlace $sourceRoot/CMakeLists.txt \
          --replace-fail 'find_package(pxr REQUIRED)' 'find_package(Threads REQUIRED)
    find_package(pxr REQUIRED)'
  '';

  CMAKE_CXX_FLAGS_INIT = "-I${lib.getDev tbb}/include";

  meta = with lib; {
    description = "ImGui Hydra Editor is a Hydra editor written in c++ with the ImGui and OpenUSD frameworks.";
    homepage = "https://github.com/raph080/ImGuiHydraEditor";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
