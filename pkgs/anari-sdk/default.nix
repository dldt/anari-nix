{
  autoPatchelfHook,
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  cmake,
  python3,
  libGL,
  glfw3,
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
  anari_helide_embree = fetchurl {
    url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip";
    hash = "sha256-Y9ZOWHlb3fbpxWT2aJVky4WHaU4CXn7HeQdyzIIYs7k=";
  };

  anari_viewer_imgui_sdl = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
in
stdenv.mkDerivation {
  pname = "anari-sdk";
  version = "v0.14.0-2-g370c6b4";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "370c6b43f84e82528ac67b4157dbcfe302ec1a4b";
    hash = "sha256-gt3BcPRuoSv+FSGPAMDFfWsoJOLlznfzjHUHGkhM5fk=";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_embree/"
    cp "${anari_helide_embree}" "''${sourceRoot}/.anari_deps/anari_helide_embree/v4.3.3.zip"
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

  nativeBuildInputs =
    [
      cmake
      python3
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      pkg-config
      autoPatchelfHook
    ];
  buildInputs =
    [
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

  cmakeFlags = [
    "-DBUILD_CTS=OFF"
    "-DBUILD_EXAMPLES=ON"
    "-DBUILD_TESTING=OFF"
    "-DBUILD_VIEWER=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DUSE_DRACO=ON"
    "-DUSE_KTX=OFF"
    "-DUSE_WEBP=ON"
    "-DVIEWER_ENABLE_GLTF=ON"

    "-DBUILD_HELIDE_DEVICE=OFF"
  ];

  meta = with lib; {
    description = "ANARI-SDK is an open-standard API for creating high-performance, power-efficient, multi-frame rendering systems.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
