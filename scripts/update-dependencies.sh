#!/usr/bin/env bash

set -eu -o pipefail

if test $# -gt 2; then
  echo 1>&2 "Syntax: $0 [<PATTERN>]"
  exit 1
fi

if git status --porcelain=v1 | grep -v "M update-deps.sh" | grep "^ M"; then
  echo "Git working has changes. Please make sure to clean those before running the script"
  exit 1
fi

CURDIR="$(realpath -e -- "${PWD}")"
PATTERN="${1:-*}"

NIX_ROOT=".?rev=$(git rev-parse HEAD)"
echo "Using ${NIX_ROOT} as a reference package set"

readarray -t PACKAGES < <(nix eval --json ${NIX_ROOT}#packages.x86_64-linux --apply 'builtins.attrNames' | jq -r '.[]')

declare -a NIX_FILES
NIX_FILES=()

for PACKAGE in "${PACKAGES[@]}"; do
  if test -n "${PACKAGE%%${PATTERN}}"; then
    continue
  fi

  if test -z "$(nix eval --raw ${NIX_ROOT}#${PACKAGE} --apply 'drv: drv.src or ""')"; then
    echo "Skipping ${PACKAGE} not defining src"
    continue
  fi

  SRC_TYPE="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src --apply builtins.typeOf)"
  case "${SRC_TYPE}" in
  path)
    echo "Skipping ${PACKAGE} using local path source path"
    continue
    ;;
  set)
    if test -n "$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src --apply 'drv: drv.url or ""')"; then
      URL="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.url)"
      IS_GITHUB="$(
        test -z "${URL//https:\/\/github.com\/*/}"
        echo $?
      )"
    else
      echo "Skipping ${PACKAGE} using unknown source"
      continue
    fi
    ;;
  *)
    echo "Skipping ${PACKAGE} using unknown source"
    continue
    ;;
  esac

  if test $IS_GITHUB == 0; then
    NIX_FILE="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.meta.position | cut -f-1 -d: | sed -e "s,/nix/store/[[:alnum:]]\+-source/,${CURDIR}/,")"
    echo "Checking for ${PACKAGE} updates hosted at ${URL} (${NIX_FILE})"

    REPO_OWNER="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.owner)"
    REPO="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.repo)"

    TAG="$(nix eval --raw ${NIX_ROOT}#${PACKAGE} --apply 'what: if what.src.tag != null then what.src.tag else ""')"
    if test -n "${TAG}"; then
      echo "Skipping ${PACKAGE} using version pinned to tag ${TAG}"
      continue
    fi

    CURRENT_HEAD="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.rev)"
    CURRENT_HASH="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.outputHash)"
    CURRENT_VERSION="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.version)"

    if test -z "${CURRENT_HEAD##v*}" -o \( "${CURRENT_HEAD}" != "${CURRENT_HEAD//./}" \); then
      NEW_HEAD="$(gh release view -R ${REPO_OWNER}/${REPO} --json tagName -q ".tagName")"
      NEW_VERSION="${NEW_HEAD}"
      unset REMOTE_HEAD
      echo "Latest tagged version ${NEW_HEAD}"
    else
      _HEAD_EVAL_STRING='src: if (src ? "branchName") && (src.branchName != null) then src.branchName else "HEAD"'
      REMOTE_HEAD="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src --apply "${_HEAD_EVAL_STRING}")"
      if test "${REMOTE_HEAD}" == "HEAD"; then
        REMOTE_HEAD="$(gh repo view ${REPO_OWNER}/${REPO} --json defaultBranchRef -q ".defaultBranchRef.name")"
      fi
      NEW_HEAD="$(gh api /repos/${REPO_OWNER}/${REPO}/commits/${REMOTE_HEAD} -q ".sha")"
      unset NEW_VERSION
      echo "Latest revision for remote ${REMOTE_HEAD} ${NEW_HEAD}"
    fi

    if test "${NEW_HEAD}" == "${CURRENT_HEAD}"; then
      echo "No update"
      continue
    fi

    if test ! -v NEW_VERSION; then
      export GIT_DIR=$(mktemp -d)
      trap "rm -fr \"${GIT_DIR}\"" EXIT
      gh repo clone "${REPO_OWNER}/${REPO}" "${GIT_DIR}" -- -q --bare --tags --single-branch -b ${REMOTE_HEAD}
      REV_SHORT="$(git rev-parse --short HEAD)"
      COMMITS_COUNT="$(git rev-list --count HEAD)"
      NEW_VERSION="$(git describe --tags 2>/dev/null || printf "v0.0.0-%d-g%s" "${COMMITS_COUNT}" "${REV_SHORT}")"
      rm -fr "${GIT_DIR}"
      unset GIT_DIR
    fi

    echo "Updating HEAD to ${NEW_HEAD}, from ${CURRENT_HEAD} (${CURRENT_VERSION} => ${NEW_VERSION})"
    NEW_SOURCE_URL="$(nix eval --raw ${NIX_ROOT}#${PACKAGE}.src.url | sed -e "s,${CURRENT_HEAD},${NEW_HEAD},")"
    case "${NEW_SOURCE_URL}" in
    *.git)
      NEW_HASH="$(nix-prefetch-git --fetch-submodules --rev "${NEW_HEAD}" "${NEW_SOURCE_URL}" 2>/dev/null | jq -r ".hash")"
      ;;
    *.tgz | *.tbz2 | *.txz | *.tar.* | *.zip)
      NEW_SHA256="$(nix-prefetch-url --unpack "${NEW_SOURCE_URL}" 2>/dev/null)"
      NEW_HASH="$(nix hash convert --hash-algo sha256 --to sri "${NEW_SHA256}")"
      ;;
    *) ;;
    esac

    echo "Updating HASH to ${NEW_HASH} (from ${CURRENT_HASH})"
    sed -e "/[[:blank:]]*rev[[:blank:]]*=[[:blank:]]*\"/s,\"${CURRENT_HEAD}\",\"${NEW_HEAD}\"," \
      -e "/[[:blank:]]*hash[[:blank:]]*=[[:blank:]]*\"/s,\"${CURRENT_HASH}\",\"${NEW_HASH}\"," \
      -e "/[[:blank:]]*version[[:blank:]]*=[[:blank:]]*\"/s,\"${CURRENT_VERSION}\",\"${NEW_VERSION}\"," -i "${NIX_FILE}"
    NIX_FILES+=("${NIX_FILE}")
  else
    echo "Don't know how to handle sources from ${URL}"
  fi
done

if test ${#NIX_FILES[@]} -ge 1; then
  echo "Formatting ${NIX_FILES[@]}"
  nix fmt "${NIX_FILES[@]}" 2> >(grep -v "warning: Git tree '$PWD' is dirty" 1>&2)

  echo "Some packages were updated. Make sure to run 'nix flake check --impure' or 'nix build .#package-that-has-been-updated --impure'."
fi
