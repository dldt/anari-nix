{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  config,
  cudaSupport ? config.cudaSupport,
  cmake,
  anari-sdk,
  libGL,
  pkg-config,
  assimp,
  cudaPackages,
  glm,
  hdf5,
  tbb,
  find-tbb-cmake,
  sdl3,
  openusd,
  xorg,
  applyPatches,
  vtk,
  runCommandNoCC,
}:
let
  visrtx-src =
    let
      owner = "NVIDIA";
      repo = "VisRTX";
    in
    applyPatches {
      inherit owner repo; # Those are not used by applyPatches, but are used by our update script.
      src = fetchFromGitHub {
        inherit owner repo;
        rev = "38b102eefab3c15d765ec8d427c7a1ca1d3ed976";
        hash = "sha256-FrMyMOpwtnOrOyjRAb2Lysi5Y6gdksJqVgAU96TMzhM=";
      };
      postPatch = ''
        cp -rv ./external/fmtlib ./tsd/external/fmtlib
        cp -rv ./external/stb_image ./tsd/external/stb_image
        substituteInPlace ./tsd/external/CMakeLists.txt \
          --replace-fail "../../external/fmtlib" "fmtlib" \
          --replace-fail "../../external/stb_image" "stb_image"
      '';
    };
  tsd-src = visrtx-src // {
    outPath = visrtx-src + "/tsd";
  };
  anari_viewer_imgui_sdl = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
  imnodes-src = fetchurl {
    url = "https://github.com/Nelarius/imnodes/archive/refs/tags/v0.5.zip";
    hash = "sha256-hRWz07KXmeLX00bSWHZ9izaqpBTEeeViOCkPySivNNk=";
  };
in
stdenv.mkDerivation {
  pname = "tsd";
  version = "v0.12.0-167-g38b102e";

  # Main source. Hosted as part of VisRTX.
  src = tsd-src;

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/tsd_ext_imnodes/"
    cp "${imnodes-src}" "''${sourceRoot}/.anari_deps/tsd_ext_imnodes/v0.5.zip"
  '';

  cmakeFlags = [
    (lib.cmakeBool "TSD_ENABLE_SERIALIZATION" true)
    (lib.cmakeBool "TSD_USE_CUDA" cudaSupport)
    (lib.cmakeBool "TSD_USE_ASSIMP" true)
    (lib.cmakeBool "TSD_USE_HDF5" true)
    (lib.cmakeBool "TSD_USE_SDL3" true)
    (lib.cmakeBool "TSD_USE_USD" true)
    (lib.cmakeBool "TSD_USE_VTK" true)
    (lib.cmakeFeature "CMAKE_MODULE_PATH" "${find-tbb-cmake}/lib/cmake")
  ];

  installPhase = ''
    mkdir -p "''${out}/bin"
    cp ./tsdViewer "''${out}/bin"
    cp ./tsdRender "''${out}/bin"
    cp ./printTSD "''${out}/bin/tsdPrint"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    assimp
    sdl3
    glm
    libGL
    hdf5
    openusd
    tbb
    find-tbb-cmake
    vtk
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    xorg.libX11
    xorg.libXt
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ];

  meta = with lib; {
    description = "This project started as a medium to learn 3D scene graph library design in C++ as well as be an ongoing study on how a scene graph and ANARI can be paired.";
    homepage = "https://github.com/jeffamstutz/TSD";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
