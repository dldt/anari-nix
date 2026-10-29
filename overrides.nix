_final: prev: {
  # anari-cts pulls imageio into its Python environment. Its PNG round-trip
  # tests fail against the Pillow version nixpkgs ships ("Invalid mode for
  # data type"); the mismatch is in the test suite's own expectations, not in
  # anything anari-cts uses.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      imageio = pythonPrev.imageio.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          "test_png_16bit"
          "test_png"
        ];
      });
    })
  ];

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
}
