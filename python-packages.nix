lib: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      _pythonFinal: pythonPrev:
      lib.packagesFromDirectoryRecursive {
        inherit (pythonPrev) callPackage newScope;
        directory = ./python-pkgs;
      }
    )
  ];
}
