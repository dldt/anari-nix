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
  silo,
  sdl3,
  openusd,
  xorg,
  vtk,
  nix-update-script,
}:
let
  anari_viewer_imgui_sdl = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
  imnodes-src = fetchurl {
    url = "https://github.com/Nelarius/imnodes/archive/refs/tags/v0.5.zip";
    hash = "sha256-hRWz07KXmeLX00bSWHZ9izaqpBTEeeViOCkPySivNNk=";
  };
  imguizmo-src = fetchurl {
    url = "https://github.com/CedricGuillemet/ImGuizmo/archive/71f14292205c3317122b39627ed98efce137086a.zip";
    hash = "sha256-kOrhHDy5hMGAC95Q1CbfpPNh1D9LQBg48I5H/GGzjRw=";
  };
in
stdenv.mkDerivation {
  pname = "tsd";
  version = "0.13.0-unstable-2026-01-22";

  # Main source. Hosted as part of VisRTX.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "2f31ae9a97fbd8da4006da2223da5fb24d012f07";
    hash = "sha256-TZdq7XlfNk8Z6SrxRr5nSZGPVdo7+2bgXj5WEY54iTY=";
  };

  patches = lib.optionals stdenv.isDarwin [
    ./fix-tsd-build-on-macos.patch
  ];
  postPatch = ''
    echo $PWD
    ls
    cp -rv ../devices/rtx/external/fmtlib ./external/fmtlib
    cp -rv ../devices/rtx/external/stb_image ./external/stb_image
    substituteInPlace ./external/CMakeLists.txt \
      --replace-fail "../../devices/rtx/external/fmtlib" "fmtlib" \
      --replace-fail "../../devices/rtx/external/stb_image" "stb_image"
  '';

  sourceRoot = "./source/tsd";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/tsd_ext_imnodes/"
    cp "${imnodes-src}" "''${sourceRoot}/.anari_deps/tsd_ext_imnodes/v0.5.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/tsd_ext_imguizmo/"
    cp "${imguizmo-src}" "''${sourceRoot}/.anari_deps/tsd_ext_imguizmo/71f14292205c3317122b39627ed98efce137086a.zip"
  '';

  cmakeFlags = [
    (lib.cmakeBool "TSD_ENABLE_SERIALIZATION" true)
    (lib.cmakeBool "TSD_USE_CUDA" cudaSupport)
    (lib.cmakeBool "TSD_USE_ASSIMP" true)
    (lib.cmakeBool "TSD_USE_HDF5" true)
    (lib.cmakeBool "TSD_USE_SDL3" true)
    (lib.cmakeBool "TSD_USE_USD" true)
    (lib.cmakeBool "TSD_USE_VTK" true)
    (lib.cmakeBool "TSD_USE_SILO" true)
  ];

  installPhase = ''
    mkdir -p "''${out}/bin"
    cp ./tsdViewer "''${out}/bin"
    cp ./tsdRender "''${out}/bin"
    cp ./tsdPrint "''${out}/bin"
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
    silo
    tbb
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "This project started as a medium to learn 3D scene graph library design in C++ as well as be an ongoing study on how a scene graph and ANARI can be paired.";
    homepage = "https://github.com/jeffamstutz/TSD";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
