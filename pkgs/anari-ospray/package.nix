{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  python3,
  embree-ispc,
  ospray,
  openvkl,
  rkcommon,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "anari-ospray";
  version = "0-unstable-2025-07-04";

  # Main source.
  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "f385a67d21ba0db314c2539bbe2f2f7e3437d97e";
    hash = "sha256-s8+89VjGjJLXKrm/Kalt4s6V18Swpl1Y7GKR6OCEfHQ=";
  };

  patches = [
    ./add-get-property-size-parameter.patch
  ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    embree-ispc
    ospray
    openvkl
    rkcommon
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Translation layer from Khronos ANARI to Intel OSPRay: ANARILibrary and ANARIDevice 'ospray'.";
    homepage = "https://github.com/ospray/anari-ospray";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
