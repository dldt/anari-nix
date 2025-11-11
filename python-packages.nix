final: prev: {
  python3Packages =
    prev.python3Packages
    // prev.lib.packagesFromDirectoryRecursive {
      inherit (prev.python3Packages) newScope;
      inherit (prev.python3Packages) callPackage;
      directory = ./python-pkgs;
    };
}
