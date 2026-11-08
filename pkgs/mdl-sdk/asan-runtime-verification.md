# OpenImageIO plugin shared-runtime patch verification

## Change

`openimageio-dynamic-gcc-runtime.patch` adds the existing per-target
`DYNAMIC_GCC_RUNTIME` argument to `shaders-plugin-openimageio`. No dependency
pins, export restrictions, sanitizer options, or application tests were changed.
The MDL source remains NVIDIA/MDL-SDK revision
`2c125342d99fed865807474afdec49c8362152e5`.

## Build and ELF checks

Executed from the packaging repository:

```sh
nix build .#mdl-sdk --no-link --print-out-paths -L
readelf -d /nix/store/0xn4dl7vwj46444y67w2pbzg93593lnf-mdl-sdk-2026.0.2/lib/nv_openimageio.so
nm -D -C /nix/store/0xn4dl7vwj46444y67w2pbzg93593lnf-mdl-sdk-2026.0.2/lib/nv_openimageio.so
sha256sum /nix/store/0xn4dl7vwj46444y67w2pbzg93593lnf-mdl-sdk-2026.0.2/lib/nv_openimageio.so
```

Build succeeded. Local build transcript: `/tmp/anari-mdl-runtime-build.log`
(not a portable evidence artifact).

- Derivation: `/nix/store/j1ai6xi7y38wravwrf7z9l6j6n4hip02-mdl-sdk-2026.0.2.drv`
- Output: `/nix/store/0xn4dl7vwj46444y67w2pbzg93593lnf-mdl-sdk-2026.0.2`
- Plugin SHA256: `afac748cc3273478e2190053577d6936086ca776d6a8089b05a678af5fd9fa29`
- ELF NEEDED now includes `libstdc++.so.6` and `libgcc_s.so.1`.
- Dynamic undefined symbols include `operator new(unsigned long)@GLIBCXX_3.4`
  and `operator delete(void*, unsigned long)@CXXABI_1.3.9`.
- Plugin RUNPATH selects `/nix/store/3bbcl52njd8d0kzmhrkx2kwa25940242-openimageio-3.1.17.0/lib`
  and `/nix/store/0ba5kj6r0zhfwd84l5vzccqvx7amlq2c-gcc-15.3.0-lib/lib`.

The original installed plugin was independently checked: its hash matches the
handoff, it lacks a shared libstdc++ dependency, and its cleanup call at
`0x1e95c` follows local addresses `0x2a080` and `0xbb1b0` to `free@plt`.
The original OIIO allocation at `0xa838a` calls `operator new@plt`.

## Limitations / remaining acceptance

This checkout uses GCC 15.3.0, CMake 4.1.6 and OIIO 3.1.17.0, not the
handoff's GCC 16.2.0, CMake 4.4.4 and OIIO 3.1.18.1. The existing flake lock
was not changed. This is a successful build and expected ELF-policy change on
the current pinned closure, not an exact reconstruction of the reported closure.

No runtime ASan/UBSan or Release regression was run. The Vela surface-test
executable was not found by a repository-aware file search under
`/home/tarcila/Code/ANARI/vela`; this does not establish that its candidate source
or ignored build outputs are unavailable. No corrected-plugin loader trace was
captured. The smaller package-owned reproducer remains unimplemented.

Before claiming the reported failure fixed, run the unchanged surface tests and
adapter control with allocation checks active, verify actual loaded libraries,
and repeat Release/reference coverage as specified in
`../../visrtx-packaging-asan-handoff.md`. In particular, do not silently mix the
old OIIO closure with this build or claim the original configuration was tested.
