final: prev:
let
  inherit (prev) lib;
in
{
  nvidia-mdl = lib.warnOnInstantiate "nvidia-mdl has been renamed to mdl-sdk to better follow upstream name usage" prev.mdl-sdk;
}
