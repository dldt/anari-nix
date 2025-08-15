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
  tbb_2021,
  sdl3,
  openusd,
  xorg,
  applyPatches,
  vtk,
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
        rev = "b7a0d4422eb9da5ddfa24c1573ff0f1a5ad5750c";
        hash = "sha256-c44E8uIYIj74c4q0E2wbvj7ZO4ytnCDeA76R656rR1g=";
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
in
stdenv.mkDerivation {
  pname = "tsd";
  version = "v0.12.0-86-gb7a0d44";

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
  ];

  installPhase = ''
    mkdir -p "''${out}/bin"
    cp ./tsdViewer "''${out}/bin"
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
    tbb_2021
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
