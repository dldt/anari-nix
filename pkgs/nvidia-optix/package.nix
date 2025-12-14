{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "nvidia-optix";
  version = "9.1.0";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "optix-dev";
    rev = "v9.1.0";
    hash = "sha256-DZqsXSbuvCsh1EXFS29H4zCm20zwBYxVKj/pvZRvSTE=";
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
