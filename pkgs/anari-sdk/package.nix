{
  autoPatchelfHook,
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  nix-update-script,
  cmake,
  python3,
  libGL,
  pkg-config,
  apple-sdk_14,
  sdl3,
}:
let
  # Additional CMAKE FetchContent support. Outputs to ${CMAKE_SOURCE_DIR}/.anari_deps/${FETCH_SOURCE_NAME}
  anari_viewer_imgui_sdl = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
in
stdenv.mkDerivation {
  pname = "anari-sdk";
  version = "0.15.0-unstable-2026-04-03";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "1331286c4078011dc4e0679c8c2a5280d4ce6b50";
    hash = "sha256-wvypG7cGbgz20DCTF5PEN4qM8giBIdxFHTNJ4WscYFo=";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
  '';

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    autoPatchelfHook
  ];
  buildInputs = [
    sdl3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libGL
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_14
  ];

  cmakeFlags = with lib; [
    (cmakeBool "BUILD_CTS" false)
    (cmakeBool "BUILD_EXAMPLES" true)
    (cmakeBool "BUILD_TESTING" false)
    (cmakeBool "BUILD_VIEWER" true)
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (cmakeBool "USE_DRACO" false)
    (cmakeBool "USE_KTX" false)
    (cmakeBool "USE_WEBP" false)
    (cmakeBool "VIEWER_ENABLE_GLTF" false)

    (cmakeBool "BUILD_HELIDE_DEVICE" false)
  ];

  # The upstream install flattens scenes/scene.h next to anari_test_scenes.h,
  # but scene.h still uses #include "../anari_test_scenes.h" (the source tree
  # relative path). Fix the include to match the flat installed layout.
  postInstall = ''
    substituteInPlace "$out/include/anari/anari_test_scenes/scene.h" \
      --replace-fail '../anari_test_scenes.h' 'anari_test_scenes.h'
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "ANARI-SDK is an open-standard API for creating high-performance, power-efficient, multi-frame rendering systems.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
