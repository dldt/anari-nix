{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "nvidia-optix";
  version = "9.0.0";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "optix-dev";
    rev = "v9.0.0";
    hash = "sha256-WbMKgiM1b3IZ9eguRzsJSkdZJR/SMQTda2jEqkeOwok=";
  };

  installPhase = ''
    mkdir -p "$out/include"
    cp -r include/* "$out/include"
  '';

  meta = with lib; {
    description = "An application framework for achieving optimal ray tracing performance on the GPU.";
    homepage = "https://developer.nvidia.com/rtx/ray-tracing/optix";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
