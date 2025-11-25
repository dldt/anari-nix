#!/usr/bin/env python

from enum import Enum
from functools import reduce
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


def getpackagenames(url):
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
            str(scriptdir / "get-package-names.nix"),
            "allPackages",
        ],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        print("Error: ", result.stderr.decode())
        return None
    return json.loads(result.stdout.decode())


# Get nix uri information
nixworkdir = str(scriptdir.resolve().parent.resolve()) + "/"

if (packagenames := getpackagenames(nixworkdir)) is None:
    sys.exit(1)

for package in packagenames:
    print(f"Updating package: {package}")
    result = subprocess.run(
        ["nix-update", "--flake", "--use-update-script", package],
        cwd=nixworkdir,
        shell=False,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        print("Error: ", result.stderr.decode())
        sys.exit(1)
