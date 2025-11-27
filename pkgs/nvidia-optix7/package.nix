{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
}:
let
  version = "7.7.0";
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "optix-dev";
    tag = "v7.7.0";
    hash = "sha256-1sX4qgtIv/tO9+LQhTXES7Pmspk6yoiolCL/D9jvsTE=";
  };

in
stdenv.mkDerivation {
  inherit src version;
  pname = "nvidia-optix7";

  installPhase = ''
    mkdir -p "$out/include"
    cp -r include/* "$out/include"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=skip"
    ];
  };

  meta = with lib; {
    description = "An application framework for achieving optimal ray tracing performance on the GPU.";
    homepage = "https://developer.nvidia.com/rtx/ray-tracing/optix";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
