{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "nvidia-optix8";
  version = "8.1.0";
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "optix-dev";
    tag = "v8.1.0";
    hash = "sha256-qNhN1N0hIPoihrFVzolo2047FomLtqyHFUQh5qW3O5o=";
  };

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
