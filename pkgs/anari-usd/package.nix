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
  version = "0.15.0_next-unstable-2026-03-01";

  src = fetchFromGitHub {
    owner = "NVIDIA-Omniverse";
    repo = "ANARI-USD";
    rev = "1454ecb102e2a48f1ee876bd7e0f371432a82b03";
    hash = "sha256-hj7wzfq5SyXsYXMTwnCi6e19HE1DGQM8PAYXQoiE090=";
  };

  patches = [
    ./0001-Use-find-components-instead-of-explicitely-iterating.patch
    ./0002-Find-X11-and-OpenGL-as-dependencies-of-OpenUSD-Mater.patch
    ./0003-Also-skip-gomp-when-flattening-usd-libraries.patch
    ./0004-Also-ignore-static-and-dylib-libraries.patch
    ./0005-Fix-build-on-MacOS.patch
    ./0006-Fix-non-const-reference-bound-to-temporary-in-GetOrC.patch
    ./0007-Fix-format-security-warning-in-snprintf-call.patch
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
