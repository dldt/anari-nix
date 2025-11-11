_final: prev: {
  embree-ispc = prev.embree.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DEMBREE_ISPC_SUPPORT=ON"
    ];
  });

  # Workaround ucx being broken with cuda
  ucx = prev.ucx.override { enableCuda = false; };
}
