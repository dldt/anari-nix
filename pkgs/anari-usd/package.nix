{
  anari-sdk,
  cmake,
  apple-sdk_14,
  fetchFromGitHub,
  lib,
  python3,
  stdenv,
  openusd,
  opensubdiv,
  materialx,
  libGL,
  libx11,
  libxt,
  tbb,
  imath,
  nix-update-script,
}:
let
  openusdCore = openusd.override {
    # ANARI-USD only needs OpenUSD library support. Nixpkgs' top-level openusd
    # enables USDView/tools, which pulls PyQt6 -> QtWebEngine and breaks on
    # aarch64-darwin.
    withUsdView = false;
    withTools = false;
  };
in
stdenv.mkDerivation {
  pname = "anari-usd";
  version = "0.15.0_next-unstable-2026-07-14";

  src = fetchFromGitHub {
    owner = "NVIDIA-Omniverse";
    repo = "ANARI-USD";
    rev = "7f54c7045c96ede4bdfc53d85ecbeeaabdc8a089";
    hash = "sha256-tsbZCXjrgwDZSqrvrhr3OiM18b/Hvy3MFlWv/RocEiU=";
  };

  patches = [
    ./0001-Use-find-components-instead-of-explicitely-iterating.patch
    ./0002-Find-X11-and-OpenGL-as-dependencies-of-OpenUSD-Mater.patch
    ./0003-Also-skip-gomp-when-flattening-usd-libraries.patch
    ./0004-Also-ignore-static-and-dylib-libraries.patch
    ./0005-Fix-build-on-MacOS.patch
    ./0006-Let-USD-find-OpenSubdiv-in-config-mode.patch
  ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    imath
    materialx
    openusdCore
    opensubdiv
    tbb
  ]
  ++ lib.optionals stdenv.isLinux [
    # What's need for MaterialX on Linux
    libx11
    libxt
    libGL
  ]
  ++ lib.optionals stdenv.isDarwin [
    apple-sdk_14
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "HdAnari is USD Hydra Render delegate enabling the use of ANARI devices inside USD.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
