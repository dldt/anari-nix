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
  version = "0.15.0_next-unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "NVIDIA-Omniverse";
    repo = "ANARI-USD";
    rev = "5fa6ef7495e437fe19de0f35ed256b317203fc3e";
    hash = "sha256-OzsA2mu8wTPK2Qy/HwNAqkZnqUJvrySledNMEbHHChg=";
  };

  patches = [
    ./0001-Use-find-components-instead-of-explicitely-iterating.patch
    ./0002-Find-X11-and-OpenGL-as-dependencies-of-OpenUSD-Mater.patch
    ./0003-Also-skip-gomp-when-flattening-usd-libraries.patch
    ./0004-Also-ignore-static-and-dylib-libraries.patch
    ./0005-Fix-build-on-MacOS.patch
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
