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
  conduit,
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
        rev = "b3411bc99b9ce55e9fbd1ea51c8824b3445c2db3";
        hash = "sha256-Qt1AgnMgv3ChmK6hc8duW7zS6D4Jake/qQiKV6w8+VM=";
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
  tbb_cmake = runCommandNoCC "findtbb.cmake" { FIND_TBB = ./FindTBB.cmake; } ''
    mkdir $out
    cp $FIND_TBB $out/
  '';
in
stdenv.mkDerivation {
  pname = "tsd";
  version = "v0.12.0-118-gb3411bc";

  # Main source. Hosted as part of VisRTX.
  src = tsd-src;

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
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
    conduit
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
