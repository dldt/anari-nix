# shellcheck shell=bash

# Only run the hook from nativeBuildInputs
(("$hostOffset" == -1 && "$targetOffset" == 0)) || return 0

guard=Sourcing
reason=

[[ -n ${cudaFilterCmakeImplicitPathsHookOnce-} ]] && guard=Skipping && reason=" because the hook has been propagated more than once"

if (("${NIX_DEBUG:-0}" >= 1)); then
  echo "$guard hostOffset=$hostOffset targetOffset=$targetOffset cuda-filter-cmake-implicit-paths-hook$reason" >&2
else
  echo "$guard cuda-filter-cmake-implicit-paths-hook$reason" >&2
fi

[[ $guard == Sourcing ]] || return 0

declare -g cudaFilterCmakeImplicitPathsHookOnce=1

# Remove some unwanted additional to what CMake detects has implicit library path.
setupImplicitDirectoryExclusions() {
  paths="$("@ccFullPath@" -E -v /dev/null |& grep LIBRARY_PATH | cut -f2 -d"=")"

  IFS=: read -r -a paths <<<"${paths}"
  export CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES_EXCLUDE
  for p in "${paths[@]}"; do
    p=$(realpath "${p}")
    if [ $? == 0 ]; then
      CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES_EXCLUDE="$(realpath ${p})${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES_EXCLUDE:+;${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES_EXCLUDE}}"
    fi
  done
}

preConfigureHooks+=(setupImplicitDirectoryExclusions)
