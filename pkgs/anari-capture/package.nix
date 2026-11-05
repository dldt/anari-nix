{
  anari-sdk,
  cmake,
  fetchFromGitHub,
  lib,
  nix-update-script,
  python3,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "anari-capture";
  version = "0.16.0-unstable-2026-11-04";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "3c858bdcf5b0c150fa6cdabf87ab15f73f4ea2d1";
    hash = "sha256-DGmYKQJLgHwSQOYJYcL2XbhvGGBCu2UPTBHM4eWRu7w=";
  };
  sourceRoot = "source/src/devices/capture";

  # Unlike helide/halcyon, the capture device's CMakeLists.txt is only meant to
  # be used as a subdirectory of the SDK build: it lacks the standalone
  # preamble (cmake_minimum_required, GNUInstallDirs, output/rpath setup).
  preConfigure = ''
    cat > cmake-preamble.txt <<'EOF'
    cmake_minimum_required(VERSION 3.11)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_BUILD_TYPE_INIT Release)
    set(CMAKE_INSTALL_RPATH "$ORIGIN")
    set(CMAKE_INSTALL_MESSAGE LAZY)
    project(anari_capture_standalone LANGUAGES CXX)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ''${CMAKE_BINARY_DIR})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ''${CMAKE_BINARY_DIR})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${CMAKE_BINARY_DIR})
    include(GNUInstallDirs)
    EOF
    cat cmake-preamble.txt CMakeLists.txt > CMakeLists.txt.new
    mv CMakeLists.txt.new CMakeLists.txt
    rm cmake-preamble.txt
  '';

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Capture device for ANARI, recording API calls for later replay and diffing.";
    homepage = "https://github.com/KhronosGroup/ANARI-SDK/tree/main/src/devices/capture";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "anariCaptureDiff";
  };
}
