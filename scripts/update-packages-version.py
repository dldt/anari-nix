#!/usr/bin/env python

from enum import Enum
from functools import reduce
from github import Auth, Github, GithubException
from itertools import islice, dropwhile
from pygit2 import clone_repository, discover_repository, GIT_DESCRIBE_TAGS, Repository
from shutil import rmtree
from tempfile import mkdtemp
from pathlib import Path

import json
import os
import re
import subprocess
import sys

# Some useful regexp
replacestorepath = re.compile(r"/nix/store/\w+-source/")
replacerev = re.compile(r'(\s*rev\s*=\s*)"([0-9a-fa-f]+)"')
replacehash = re.compile(r'(\s*hash\s*=\s*)"([+-=/\w]+)"')
replaceversion = re.compile(r'(\s*version\s*=\s*)"([-.\w]+)"')

# Script dir
scriptdir = Path(__file__).resolve().parent


def getpackages(url):
    url = url.rstrip("/")
    result = subprocess.run(
        [
            "nix",
            "eval",
            "--accept-flake-config",
            "--json",
            "--arg",
            "flake-path",
            url,
            "--file",
            str(scriptdir / "get-package-details.nix"),
            "details",
        ],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        print("Error: ", result.stderr.decode())
        return None
    return json.loads(result.stdout.decode())


def checkrepostatus(repo):
    repostatus = repo.status()
    del repostatus["flake.nix"]
    del repostatus["scripts/update-packages-version.py"]
    del repostatus["scripts/get-package-details.nix"]
    if len(repostatus) != 0:
        print("Error: There are uncommitted changes")
        changes = iter(repostatus.keys())
        for change in islice(changes, 10):
            print("  ", change)
        if next(changes, None):
            print("  ...")
        sys.exit(1)


# Get repo and nix uri information
nixreporoot = discover_repository(".")
nixrepo = Repository(nixreporoot)
nixworkdir = nixrepo.workdir

if (packages := getpackages(nixworkdir)) is None:
    sys.exit(1)
if type(packages) is not dict:
    print("Error: invalid package description.")
    sys.exit(1)

auth = (tk := os.environ.get("GITHUB_TOKEN")) and Auth.Token(tk) or None

updatedfiles = []

nixversionstr = subprocess.run(
    ["nix", "--version"], check=True, stdout=subprocess.PIPE
).stdout.decode()


class NixFlavor(Enum):
    UNKNOWN = -1
    CPP_NIX = 1
    LIX = 2
    DETERMINATE = 3


nixflavor = NixFlavor.UNKNOWN

if "(Lix, like Nix)" in nixversionstr:
    nixflavor = NixFlavor.LIX
elif "(Nix)" in nixversionstr:
    nixflavor = NixFlavor.CPP_NIX
elif "(Determinate Nix" in nixversionstr:
    nixflavor = NixFlavor.DETERMINATE
else:
    raise RuntimeError("Cannot detect the version of nix being used.")

with Github(auth=auth) as g:
    for name, desc in packages.items():
        if not "sourcetype" in desc:
            print(f"Skipping {name} using unknown source")
            continue
        if desc["sourcetype"] == "github":
            try:
                print(
                    f"Checking {name} for update, using github source, defined in {desc["definition"]}"
                )
                if "tag" in desc:
                    print(f"  Pinned to an explicit tag {desc["tag"]}. Skipping.")
                    continue

                if "rev" not in desc:
                    print(f"  No revision specified. This is unexpected. Skipping.")
                    continue

                if "version" not in desc:
                    print(f"  No version specified. This is unexpected. Skipping.")
                    continue

                # Get updated revision information
                currenthead = desc["rev"]
                currentversion = desc["version"]
                newhead = None
                newversion = None
                remotehead = None

                nixrepo = g.get_repo(f"{desc["owner"]}/{desc["repo"]}")
                if len(desc["rev"]) in (40, 64) and all(
                    c in "0123456789abcdef" for c in desc["rev"]
                ):
                    remotehead = desc.get("ref", nixrepo.default_branch)
                    newhead = nixrepo.get_branch(remotehead).commit.sha
                else:
                    newhead = next(
                        dropwhile(lambda r: r.prerelease, nixrepo.get_releases()), None
                    )
                    if newhead is None:
                        print(f"  Cannot find a valid new release. Skipping")
                        continue
                    newhead = newhead.tag_name
                    remotehead = newhead
                    newversion = newhead

                if newhead is None or newhead == currenthead or remotehead is None:
                    print("  No new version found. Skipping")
                    continue

                # Build a new version number if we don't have one
                if newversion is None:
                    if remotehead is None:
                        print("  No remote head found. Skipping.")
                    tmpdir = mkdtemp()
                    try:
                        clone = clone_repository(
                            nixrepo.clone_url,
                            tmpdir,
                            bare=False,
                            checkout_branch=remotehead,
                        )
                        try:
                            newversion = clone.describe(
                                describe_strategy=GIT_DESCRIBE_TAGS
                            )
                        except Exception as e:
                            count = reduce(
                                lambda acc, _: acc + 1, clone.walk(clone.head.target), 0
                            )
                            newversion = f"v0.0.0-{count}-g{clone.head.peel().short_id}"
                    except Exception as e:
                        print(f"  Error: {e}")
                        continue
                    else:
                        rmtree(tmpdir)

                # Compute new package hash
                currenturl = desc["url"]
                currenthash = desc["hash"]
                if currenturl.endswith(".git"):
                    # Given our use of fetchFromGithub, A git url usually implies that we are fetching submodules too. Otherwise, that would be an archive.
                    result = subprocess.run(
                        [
                            "nix-prefetch-git",
                            "--fetch-submodules",
                            "--rev",
                            newhead,
                            currenturl,
                        ],
                        check=False,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )
                    if result.returncode != 0:
                        print("  Failed fetching from url {cururl}: ", result.stderr)
                        continue
                    newhash = json.loads(result.stdout.decode().strip())["hash"]
                elif (
                    currenturl.endswith(".tgz")
                    or currenturl.endswith(".tbz2")
                    or currenturl.endswith(".txz")
                    or currenturl.endswith(".zip")
                    or currenturl.endswith(".tar.gz")
                    or currenturl.endswith(".tar.bz2")
                    or currenturl.endswith(".tar.xz")
                ):
                    newurl = currenturl.replace(currenthead, newhead)
                    result = subprocess.run(
                        ["nix-prefetch-url", "--unpack", newurl],
                        check=False,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )
                    if result.returncode != 0:
                        print("  Failed fetching from url {cururl}: ", result.stderr)
                        continue
                    newsha256 = result.stdout.decode().strip()
                    if (
                        nixflavor == NixFlavor.CPP_NIX
                        or nixflavor == NixFlavor.DETERMINATE
                    ):
                        result = subprocess.run(
                            [
                                "nix",
                                "hash",
                                "convert",
                                "--hash-algo",
                                "sha256",
                                "--to",
                                "sri",
                                newsha256,
                            ],
                            check=False,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                        )
                    elif nixflavor == NixFlavor.LIX:
                        result = subprocess.run(
                            [
                                "nix",
                                "hash",
                                "to-sri",
                                "--type",
                                "sha256",
                                newsha256,
                            ],
                            check=False,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                        )
                    if result.returncode != 0:
                        print(
                            "  Failed converting hash {newsha256} to sri: ",
                            result.stderr.decode(),
                        )
                        continue
                    newhash = result.stdout.decode().strip()

                else:
                    print(f"  Skipping {name} using unsupported url {currenturl}")
                    continue

                currenturl = desc["url"]
                newurl = currenturl.replace(currenthead, newhead)

                print(f"  Updating from {currentversion} to {newversion} ({newhash})")

                sourcenix = desc["definition"]
                targetnix = replacestorepath.sub(nixworkdir, sourcenix)
                print(f"    Updating {sourcenix} to {targetnix}")

                with open(sourcenix, "rt") as f:
                    content = f.read()

                replaceexisting = lambda what, withwhat: lambda m: (
                    f'{m.group(1)}"{withwhat}"' if m.group(2) == what else m.group(0)
                )

                content = replacerev.sub(replaceexisting(currenthead, newhead), content)
                content = replacehash.sub(
                    replaceexisting(currenthash, newhash), content
                )
                content = replaceversion.sub(
                    replaceexisting(currentversion, newversion), content
                )

                with open(targetnix, "w+t") as f:
                    f.write(content)

                updatedfiles.append(targetnix)

            except GithubException as e:
                # Can happen if the token is not allow to access organization content or like. Solution would be to not use a token
                # as we don't deal with private repositories
                # But then, how to deal with rate limiting?
                print(f"Error: {e}")
                continue

        else:
            print(f"Skipping {name} using unsupported source type {desc["sourcetype"]}")
            continue

if updatedfiles:
    print(f"Formatting {len(updatedfiles)} files")
    result = subprocess.run(
        ["nix", "fmt"] + updatedfiles,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        print("Error: ", result.stderr)
        sys.exit(1)

    print(
        "Some packages were updated. Make sure to run 'nix flake check --impure' or 'nix build .#package-that-has-been-updated --impure'."
    )
