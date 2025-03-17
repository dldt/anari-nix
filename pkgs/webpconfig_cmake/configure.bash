#!/usr/bin/env -S bash -e -o pipefail

# set -x

trim() {
  # https://stackoverflow.com/a/3352015
  local var="$*"
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

libs=("libsharpyuv") # "libwebpdecoder")
for lib in "${libs[@]}"; do
  files=("os x/lib/${lib}."*\(dylib\|so\)*)
  for file in "${files[@]}"; do
    echo "FILE ${file}"
  done
done
