_final: prev: {
  embree-ispc = prev.embree.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DEMBREE_ISPC_SUPPORT=ON"
    ];
  });

  sse2neon = prev.sse2neon.overrideAttrs (_old: {
    src = prev.fetchFromGitHub {
      owner = "DLTcollab";
      repo = "sse2neon";
      rev = "31532745b49d7dd7ff58c56df68f1fc3949e4db5";
      hash = "sha256-AU52k6Of761ewHXD68ZNT9HbenE5xBT2kMdenFbaSxE=";
    };
    doCheck = false;
  });

  # Workaround ucx being broken with cuda
  ucx = prev.ucx.override { enableCuda = false; };
}
