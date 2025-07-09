{
  lib,
  stdenv,
  fetchFromGitHub,
}:
let
  version = "v9.0.0";
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "optix-dev";
    rev = version;
    hash = "sha256-WbMKgiM1b3IZ9eguRzsJSkdZJR/SMQTda2jEqkeOwok=";
  };

in
stdenv.mkDerivation {
  inherit src version;
  pname = "nvidia-optix";

  installPhase = ''
    mkdir -p "$out/include"
    cp -r include/* "$out/include"
  '';

  meta = with lib; {
    description = "An application framework for achieving optimal ray tracing performance on the GPU.";
    homepage = "https://developer.nvidia.com/rtx/ray-tracing/optix";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
  };
}
