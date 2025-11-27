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
  xorg,
  tbb,
  imath,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "anari-usd";
  version = "0.10.0-unstable-2025-01-07";

  src = fetchFromGitHub {
    owner = "NVIDIA-Omniverse";
    repo = "ANARI-USD";
    rev = "13bb5ef1a436d4569a5ea5576c88e35b673fb4ba";
    hash = "sha256-QiQK6U5lAcWxMcJ3DQnU22dw7zd5nh6nJVpwl/Gv+qY=";
  };

  patches = [
    ./0001-Use-find-components-instead-of-explicitely-iterating.patch
    ./0002-Find-X11-and-OpenGL-as-dependencies-of-OpenUSD-Mater.patch
    ./0003-Also-skip-gomp-when-flattening-usd-libraries.patch
    ./0004-Workaround-compatibility-with-latest-ANARI-SDK.patch
    ./0005-Also-ignore-static-and-dylib-libraries.patch
    ./0006-Fix-build-on-MacOS.patch
  ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    imath
    materialx
    openusd
    opensubdiv
    tbb
  ]
  ++ lib.optionals stdenv.isLinux [
    # What's need for MaterialX on Linux
    xorg.libX11
    xorg.libXt
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
