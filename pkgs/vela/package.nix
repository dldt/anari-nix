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
  boost,
  cudaPackages,
  glm,
  hdf5,
  libjpeg_turbo,
  opensubdiv,
  tbb,
  silo,
  sdl3,
  sol2,
  openusd,
  libx11,
  libxt,
  vtk,
  zlib,
  python3,
  nix-update-script,
}:
let
  imgui-src = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.91.7-docking.zip";
    hash = "sha256-glnDJORdpGuZ8PQ4uBYfeOh0kmCzJmNnI9zHOnSwePQ=";
  };
  imguizmo-src = fetchurl {
    url = "https://github.com/CedricGuillemet/ImGuizmo/archive/71f14292205c3317122b39627ed98efce137086a.zip";
    hash = "sha256-kOrhHDy5hMGAC95Q1CbfpPNh1D9LQBg48I5H/GGzjRw=";
  };
  openusdCore = openusd.override {
    # Vela only needs OpenUSD library support. Nixpkgs' top-level openusd enables
    # USDView/tools, which pulls PyQt6 -> QtWebEngine and breaks on aarch64-darwin.
    withUsdView = false;
    withTools = false;
  };
in
stdenv.mkDerivation {
  pname = "vela";
  version = "0-unstable-2026-10-07";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "Vela";
    rev = "8d89901c567c0fca43c87a39073b3eea0f6eb5a1";
    hash = "sha256-5bCc7zk9UP4QS26jb6EVtwiLtgwbs4yMt1oa63TndzY=";
  };

  # anari_sdk_fetch_project() downloads into `.anari_deps/<name>` under the
  # source root; seeding it there keeps the build offline.
  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/vela_ext_imgui_sdl/"
    cp "${imgui-src}" "''${sourceRoot}/.anari_deps/vela_ext_imgui_sdl/v1.91.7-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/vela_ext_imguizmo/"
    cp "${imguizmo-src}" "''${sourceRoot}/.anari_deps/vela_ext_imguizmo/71f14292205c3317122b39627ed98efce137086a.zip"
  '';

  patches = [
    ./0001-fix-io-build-against-OpenUSD-25.05.patch
    # Shared with anari-vsr, which references it from here.
    ./0002-fetch-imnodes-only-for-viskores-demo.patch
    ./0003-make-the-anari-device-library-optional.patch
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    # The device is anari-vsr's to ship; building it here would have both
    # packages carry the same library.
    (lib.cmakeBool "VSR_BUILD_ANARI_DEVICE" false)
    (lib.cmakeBool "VSR_USE_CUDA" cudaSupport)
    (lib.cmakeBool "VSR_USE_ASSIMP" true)
    (lib.cmakeBool "VSR_USE_HDF5" true)
    (lib.cmakeBool "VSR_USE_LUA" true)
    (lib.cmakeBool "VSR_USE_NETWORKING" true)
    (lib.cmakeBool "VSR_USE_SDL3" true)
    (lib.cmakeBool "VSR_USE_TURBOJPEG" true)
    (lib.cmakeBool "VSR_USE_SILO" true)
    (lib.cmakeBool "VSR_USE_TBB" true)
    (lib.cmakeBool "VSR_USE_USD" true)
    (lib.cmakeBool "VSR_USE_VTK" true)
  ];

  # Only the USD file format plugin has an install rule; every application is
  # left in CMAKE_RUNTIME_OUTPUT_DIRECTORY, which the top-level CMakeLists sets
  # to the build root. Install whatever landed there rather than naming apps
  # one by one -- a hardcoded list silently drops anything upstream adds, which
  # is how vsrConvert went missing.
  postInstall = ''
    mkdir -p "''${out}/bin"
    installed=()
    for app in ./*; do
      [ -f "''${app}" ] || continue
      [ -x "''${app}" ] || continue
      case "''${app}" in
        *.so | *.so.* | *.a | *.dylib | *.cmake) continue ;;
      esac
      cp "''${app}" "''${out}/bin/"
      installed+=("$(basename "''${app}")")
    done

    echo "vela: installed ''${#installed[@]} applications: ''${installed[*]}"

    # Guard against the glob silently matching nothing useful if upstream
    # changes the output layout. The CUDA demos only exist when VSR_USE_CUDA
    # is on, so they are only required then.
    expected=(
      scivisStudio
      scivisStudioClient
      scivisStudioServer
      vsrConvert
      vsrPrint
      vsrRemoteViewer
      vsrServer
      vsrViewer
    )
    ${lib.optionalString cudaSupport ''
      expected+=(vsrDemoAnimatedParticles vsrDemoAnimatedVolume)
    ''}
    for app in "''${expected[@]}"; do
      if [ ! -x "''${out}/bin/''${app}" ]; then
        echo "vela: expected application ''${app} was not installed" >&2
        exit 1
      fi
    done
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    assimp
    # vsr_network is boost.asio, which VSR_USE_NETWORKING turns on; turbojpeg
    # encodes SciVis Studio's remote frames.
    boost
    libjpeg_turbo
    sdl3
    glm
    libGL
    lua54Packages.lua
    hdf5
    opensubdiv
    openusdCore
    silo
    sol2
    tbb
    vtk
    zlib
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
    description = "Scene graph library and applications pairing a live, editable scene description with ANARI devices";
    homepage = "https://github.com/NVIDIA/Vela";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
