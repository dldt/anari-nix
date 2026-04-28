{
  anari-sdk,
  apple-sdk_14,
  autoPatchelfHook,
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  libGL,
  nix-update-script,
  pkg-config,
  sdl3,
  stdenv,
}:
let
  cat_cli11 = fetchurl {
    url = "https://github.com/CLIUtils/CLI11/archive/refs/tags/v2.5.0.zip";
    hash = "sha256-iHJwyuN0oLniKzlkf5/EvHQlh/sm1qIh2i0rvPMQmws=";
  };
  cat_implot = fetchurl {
    url = "https://github.com/epezent/implot/archive/refs/tags/v0.16.zip";
    hash = "sha256-JPdyxoj2uKbhnX78EOSSOgSpFfE9SHsIuDVTqmKuFwg=";
  };
  # The viewer component is rebuilt from installed sources at find_package
  # time, and it fetches imgui via anari_sdk_fetch_project.
  anari_viewer_imgui_sdl = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
in
stdenv.mkDerivation {
  pname = "anari-cat";
  version = "0.15.0-unstable-2026-04-27";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "1c82885762ee1fe031c368dc756f15d5fa83be11";
    hash = "sha256-mvAUHSIrdMtZVrQnqe0/QCwZFHgOdM5xV1pad06Rvzo=";
  };
  sourceRoot = "source/cat";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/cat_cli11/"
    cp "${cat_cli11}" "''${sourceRoot}/.anari_deps/cat_cli11/v2.5.0.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/cat_implot/"
    cp "${cat_implot}" "''${sourceRoot}/.anari_deps/cat_implot/v0.16.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
  '';

  # Move find_package(anari) before add_subdirectory(external) so that
  # anari_sdk_fetch_project is available when building standalone.
  #
  # The installed SDK puts scene.h flat in the anari_test_scenes include dir,
  # so fix the include path to match.
  postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace-fail \
            'add_subdirectory(external)

    project(anariCat LANGUAGES C CXX)

    if (NOT TARGET anari::anari)
      find_package(anari REQUIRED COMPONENTS viewer anari_test_scenes)
    endif()' \
            'project(anariCat LANGUAGES C CXX)

    if (NOT TARGET anari::anari)
      find_package(anari REQUIRED COMPONENTS viewer anari_test_scenes)
    endif()

    add_subdirectory(external)'

    substituteInPlace Application.cpp windows/SceneSelector.cpp \
      --replace-fail \
        '#include "anari_test_scenes/scenes/scene.h"' \
        '#include "anari/anari_test_scenes/scene.h"'
  '';

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    autoPatchelfHook
  ];

  buildInputs = [
    anari-sdk
    sdl3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libGL
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_14
  ];

  cmakeFlags = with lib; [
    (cmakeBool "INSTALL_CAT" true)
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Capability Analysis Tool for ANARI renderers.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
