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
  glfw3,
  pkg-config,
  dbus,
  assimp,
  cudaPackages,
  glm,
  hdf5,
  conduit,
  tbb_2021_11,
}:
let
  visrtx-src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "7cfa08d41a15b504572533136ca8c654d1d223f0";
    hash = "sha256-q6NSW/8SXeHNOgzgMIYn32KjFU9LTHFOBx1EIRetffc=";
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
  pname = "tsd";
  version = "v0.10.1-75-g7cfa08d";

  # Main source. Hosted as part of VisRTX.
  src = visrtx-src // {
    outPath = visrtx-src + "/tsd";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_imgui_glfw/"
    cp "${anari_viewer_imgui_glfw}" "''${sourceRoot}/.anari_deps/anari_viewer_imgui_glfw/v1.91.0-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/anari_viewer_nfd/"
    cp "${anari_viewer_nfd}" "''${sourceRoot}/.anari_deps/anari_viewer_nfd/v1.2.1.zip"
  '';

  cmakeFlags = [
    "-DNFD_PORTAL=ON"
    "-DTSD_ENABLE_SERIALIZATION=ON"
    "-DTSD_USE_CUDA=${if cudaSupport then "ON" else "OFF"}"
    "-DTSD_USE_ASSIMP=ON"
    "-DTSD_USE_HDF5=ON"
  ];

  installPhase = ''
    mkdir -p "''${out}/bin"
    for target in tsdMaterialExplorer tsdViewer tsdVolumeViewer
    do
        cp "''${target}" "''${out}/bin/"
    done
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
      dbus
      glfw3
      glm
      libGL
      hdf5
      tbb_2021_11
    ]
    ++ lib.optional cudaSupport [
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
