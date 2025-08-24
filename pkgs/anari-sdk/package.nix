{
  autoPatchelfHook,
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  cmake,
  python3,
  libGL,
  pkg-config,
  apple-sdk_11,
  tinygltf,
  libwebp,
  webpconfig_cmake,
  draco,
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
  version = "v0.14.1-15-g1994f0b";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "1994f0b10d36b22519381931324e940bcb563a8d";
    hash = "sha256-Vi/nvZzT8t6P7YHicvzaXRN46x5TWAfJF14jvhkai/U=";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/"
    cp "${anari_viewer_imgui_sdl}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_sdl/v1.91.7-docking.zip"
  '';

  postInstall =
    (
      if stdenv.hostPlatform.isLinux then
        ''
          patchelf --remove-rpath anariViewer
        ''
      else
        ''
          install_name_tool \
             -change @rpath/libanari.0.dylib ''${out}/lib/libanari.0.dylib \
             -change @rpath/libanari_test_scenes.dylib ''${out}/lib/libanari_test_scenes.dylib ./anariViewer
        ''
    )
    + ''
      mkdir -p "''${out}/bin"
      cp "anariViewer" "''${out}/bin/anariViewer"
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
    tinygltf
    libwebp
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libGL
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_11
  ];

  propagatedBuildInputs = [
    draco
    webpconfig_cmake
  ];

  cmakeFlags = with lib; [
    (cmakeBool "BUILD_CTS" false)
    (cmakeBool "BUILD_EXAMPLES" true)
    (cmakeBool "BUILD_TESTING" false)
    (cmakeBool "BUILD_VIEWER" true)
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (cmakeBool "USE_DRACO" true)
    (cmakeBool "USE_KTX" false)
    (cmakeBool "USE_WEBP" true)
    (cmakeBool "VIEWER_ENABLE_GLTF" true)

    (cmakeBool "BUILD_HELIDE_DEVICE" false)
  ];

  meta = with lib; {
    description = "ANARI-SDK is an open-standard API for creating high-performance, power-efficient, multi-frame rendering systems.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
