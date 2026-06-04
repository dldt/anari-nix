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
  lua54Packages,
  pkg-config,
  assimp,
  cudaPackages,
  glm,
  hdf5,
  tbb,
  silo,
  sdl3,
  sol2,
  openusd,
  libx11,
  libxt,
  vtk,
  nix-update-script,
}:
let
  tsd_ext_imgui_sdl = fetchurl {
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
  version = "0.13.0-unstable-2026-06-04";

  outputs = [
    "out"
    "dev"
  ];

  # Main source. Hosted as part of VisRTX.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "df59f01c592a8ab69dcbae90220f436ba55f1b3d";
    hash = "sha256-R4yS752Z8Kz/E6oRnDoL4tSAYIEju/M2MKnwgIF6Ctg=";
  };

  postPatch = ''
        cp -rv ../devices/rtx/external/fmtlib ./external/fmtlib
        cp -rv ../devices/rtx/external/nonstd ./external/nonstd
        cp -rv ../devices/rtx/external/stb_image ./external/stb_image
        substituteInPlace ./external/CMakeLists.txt \
          --replace-fail "add_subdirectory(
      \''${CMAKE_CURRENT_LIST_DIR}/../../devices/rtx/external
      \''${CMAKE_CURRENT_BINARY_DIR}/tsd_visrtx_external
    )" "add_subdirectory(fmtlib)
    add_subdirectory(nonstd)
    add_subdirectory(stb_image)"
  '';

  patches = [
    ./0001-fix-macOS-Retina-UI-scale-using-ImFontConfig-RasterizerDensity.patch
    ./0002-Application-expose-pixel-density-and-set-ImGui-Displ.patch
    ./0003-Include-cstdint-for-SIZE_MAX.patch
  ];

  patchFlags = [
    "-p2"
  ];

  sourceRoot = "./source/tsd";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/tsd_ext_imgui_sdl/"
    cp "${tsd_ext_imgui_sdl}" "''${sourceRoot}/.anari_deps/tsd_ext_imgui_sdl/v1.91.7-docking.zip"
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
    runHook preInstall

    install -Dm755 -t "$out/bin" \
      ./tsdViewer \
      ./tsdRender \
      ./tsdPrint \
      ./tsdLua \
      ./obj2header \
      ./tsdOffline \
      ./tsdVolumeToNanoVDB

    mkdir -p "$dev/include/tsd" "$dev/lib/cmake/tsd"

    # Public TSD headers: consumers include <tsd/scene/Scene.hpp>, etc.
    cp -r "$NIX_BUILD_TOP/$sourceRoot/src/tsd/." "$dev/include/tsd/"

    # All static archives (flat in the build dir).
    find . -maxdepth 1 -name '*.a' -exec cp {} "$dev/lib/" \;

    # tsd_ui_imgui is an OBJECT library (no archive); bundle its objects.
    ui_objs=$(find . -path '*tsd_ui_imgui*' -name '*.o' 2>/dev/null || true)
    [ -n "$ui_objs" ] && ar rcs "$dev/lib/libtsd_ui_imgui.a" $ui_objs

    # Third-party headers that TSD's public headers #include.
    for d in deps/source build/deps/source .anari_deps; do
      [ -d "$d" ] && find "$d" \( -name '*.h' -o -name '*.hpp' \) \
        -exec cp {} "$dev/include/" \; 2>/dev/null || true
    done
    find "$NIX_BUILD_TOP/$sourceRoot/external" -name 'imoguizmo*.h*' \
      -exec cp {} "$dev/include/" \; 2>/dev/null || true

    extraFindDeps=""
    extraLinkLibs=""
    if printf '%s' "$cmakeFlags" | grep -iqE -- '-DTSD_USE_SDL3(:[A-Z]+)?=(ON|TRUE|YES|1)'; then
      extraFindDeps="find_dependency(SDL3)"
      extraLinkLibs=" SDL3::SDL3"
    fi
    substitute ${./tsd-config.cmake.in} "$dev/lib/cmake/tsd/tsd-config.cmake" \
      --subst-var-by TSD_EXTRA_FIND_DEPS "$extraFindDeps" \
      --subst-var-by TSD_EXTRA_LINK_LIBS "$extraLinkLibs"

    runHook postInstall
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
    lua54Packages.lua
    hdf5
    openusd
    silo
    sol2
    tbb
    vtk
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libx11
    libxt
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
    description = "3D scene graph library and viewer built around the ANARI rendering API";
    homepage = "https://github.com/jeffamstutz/TSD";
    license = licenses.bsd3;
    mainProgram = "tsdViewer";
    platforms = platforms.unix;
  };
}
