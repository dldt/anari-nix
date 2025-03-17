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
  dbus,
  darwin,
  tinygltf,
  libwebp,
  webpconfig_cmake,
  draco,
}:
let
  # Additional CMAKE FetchContent support. Outputs to ${CMAKE_SOURCE_DIR}/.anari_deps/${FETCH_SOURCE_NAME}
  anari_helide_embree = fetchurl {
    url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip";
    hash = "sha256-Y9ZOWHlb3fbpxWT2aJVky4WHaU4CXn7HeQdyzIIYs7k=";
  };

  anari_viewer_imgui_glfw = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.0-docking.zip";
    hash = "sha256-ZXsiXZn9NM4Qo70NoqcjWTYq5wmndIEaoi7jAIVmAkA=";
  };

  anari_viewer_nfd = fetchurl {
    url = "https://github.com/btzy/nativefiledialog-extended/archive/refs/tags/v1.2.1.zip";
    hash = "sha256-/DWbIS5WARkxuQv0JBBX7d7EUwi7TYuaq037L3DjshE=";
  };
in
stdenv.mkDerivation {
  pname = "anari-sdk";
  version = "v0.13.1-3-gae6bcdc";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "ae6bcdc0eb6d369529212075db412999d89fdd6c";
    hash = "sha256-hRR+6M7p2AtPyI4CHZmLdEL2a9SKU61u2tsVHxagxS8=";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_embree/"
    cp "${anari_helide_embree}" "''${sourceRoot}/.anari_deps/anari_helide_embree/v4.3.3.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_glfw/"
    cp "${anari_viewer_imgui_glfw}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_glfw/v1.91.0-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_nfd/"
    cp "${anari_viewer_nfd}" "''${sourceRoot}/.anari_deps/anari_viewer_nfd/v1.2.1.zip"
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
      glfw3
      tinygltf
      libwebp
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libGL
      dbus
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin (
      with darwin.apple_sdk.frameworks;
      [
        AppKit
        UniformTypeIdentifiers
      ]
    );

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
    "-DNFD_PORTAL=ON"
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
