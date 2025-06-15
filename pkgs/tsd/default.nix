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
  tbb_2021_11,
  sdl3,
  openusd,
  xorg,
  applyPatches,
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
        rev = "532cd8f61178a23b30c86214289224a835bf96ad";
        hash = "sha256-l4EpyS941U/JDDsKf5mM7xbPr44jvYVXooy6F2oH5qI=";
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
  version = "v0.11.0-137-g532cd8f";

  # Main source. Hosted as part of VisRTX.
  src = tsd-src;

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
  '';

  cmakeFlags = [
    "-DTSD_ENABLE_SERIALIZATION=ON"
    "-DTSD_USE_CUDA=${if cudaSupport then "ON" else "OFF"}"
    "-DTSD_USE_ASSIMP=ON"
    "-DTSD_USE_HDF5=ON"
    "-DTSD_USE_SDL3=ON"
  ];

  installPhase = ''
    mkdir -p "''${out}/bin"
    cp ./tsdViewer "''${out}/bin"
  '';

  nativeBuildInputs =
    [
      cmake
      pkg-config
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages.cuda_nvcc
    ];

  buildInputs =
    [
      anari-sdk
      assimp
      conduit
      sdl3
      glm
      libGL
      hdf5
      openusd
      tbb_2021_11
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
