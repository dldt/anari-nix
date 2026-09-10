lib: _final: prev: {
  anari-barney = lib.warnOnInstantiate "anari-barney has been merged into barney, following upstream: barney now builds the ANARI device directly" prev.barney;
  nvidia-mdl = lib.warnOnInstantiate "nvidia-mdl has been renamed to mdl-sdk to better follow upstream name usage" prev.mdl-sdk;
  tsd = lib.warnOnInstantiate "tsd has been split out of VisRTX and renamed to vela, following upstream at github.com/NVIDIA/Vela" prev.vela;
}
