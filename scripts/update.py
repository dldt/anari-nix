#!/usr/bin/env python3

"""
Update script that parses all packages from the flake and runs their update scripts.
For packages with passthru.updateScript, it extracts and runs the update command.
For packages without it, falls back to: nix-update --flake <package-name>
"""

import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def run_nix_eval(args: List[str]) -> Optional[str]:
    """Run nix eval command and return the output."""
    try:
        result = subprocess.run(
            ["nix", "eval", "--json"] + args,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running nix eval: {e.stderr}", file=sys.stderr)
        return None


def get_all_packages(flake_path: str) -> Optional[List[str]]:
    """Get all unique package names from the flake across all systems."""
    output = run_nix_eval(
        [
            "--accept-flake-config",
            f"{flake_path}#packages",
        ]
    )

    if output is None:
        return None

    try:
        packages_by_system = json.loads(output)
        # Collect unique package names across all systems
        package_names = set()
        for system_packages in packages_by_system.values():
            package_names.update(system_packages.keys())
        return sorted(package_names)
    except (json.JSONDecodeError, AttributeError) as e:
        print(f"Error parsing package list: {e}", file=sys.stderr)
        return None


def get_update_script(flake_path: str, package_name: str) -> Optional[List[str]]:
    """
    Get the update script for a package.
    Returns the command as a list of arguments, or None if no updateScript exists.
    """
    # Try all supported systems until we find the package
    systems = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]

    for system in systems:
        try:
            result = subprocess.run(
                [
                    "nix",
                    "eval",
                    "--json",
                    "--accept-flake-config",
                    f"{flake_path}#packages.{system}.{package_name}.passthru.updateScript",
                ],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,  # Suppress errors when attribute doesn't exist
                text=True,
            )
            output = result.stdout
            if output:
                break
        except subprocess.CalledProcessError:
            # Attribute doesn't exist for this system, try next
            continue
    else:
        # No system had this package with an updateScript
        return None

    try:
        update_script_data = json.loads(output)

        # The updateScript can be either:
        # 1. A list of command arguments
        # 2. A derivation path (string starting with /nix/store)
        if isinstance(update_script_data, list):
            # It's already a command list, return it directly
            if update_script_data[0].endswith("/nix-update"):
                update_script_data[0] = "nix-update"
            return update_script_data
        elif isinstance(update_script_data, str) and update_script_data.startswith(
            "/nix/store"
        ):
            # It's a store path, run it directly
            return [update_script_data]

        return None
    except (json.JSONDecodeError, AttributeError):
        return None


def get_fallback_command(package_name: str) -> List[str]:
    """Get the fallback update command for a package."""
    return ["nix-update", "--flake", package_name]


def run_update(
    package_name: str, command: List[str], flake_path: str
) -> Tuple[str, bool, str]:
    """
    Run the update command for a package.
    Returns (package_name, success, output).
    """
    cmd_str = " ".join(command)
    print(f"Updating {package_name}: {cmd_str}")
    try:
        result = subprocess.run(
            command,
            cwd=flake_path,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=300,  # 5 minute timeout per package
        )
        return (package_name, True, result.stdout)
    except subprocess.CalledProcessError as e:
        return (package_name, False, e.output)
    except subprocess.TimeoutExpired:
        return (package_name, False, "Update timed out after 5 minutes")


def main():
    # Get the flake directory (parent of scripts directory)
    script_dir = Path(__file__).resolve().parent
    flake_dir = script_dir.parent
    flake_path = str(flake_dir)

    print(f"Finding packages in flake at {flake_path}...")
    packages = get_all_packages(flake_path)

    if packages is None:
        print("Failed to get package list", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(packages)} packages")

    # Prepare update commands for all packages
    update_tasks = []
    for package in packages:
        # Try to get the update script from passthru
        update_script = get_update_script(flake_path, package)

        if update_script is not None:
            command = update_script + [package]
        else:
            # Fall back to nix-update
            command = get_fallback_command(package)

        update_tasks.append((package, command))

    print(f"\nStarting updates (running up to 4 in parallel)...")

    # Run updates in parallel
    success_count = 0
    failure_count = 0

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {
            executor.submit(run_update, pkg, cmd, flake_path): pkg
            for pkg, cmd in update_tasks
        }

        for future in as_completed(futures):
            package_name, success, output = future.result()
            if success:
                print(f"✓ {package_name}: Success")
                success_count += 1
            else:
                print(f"✗ {package_name}: Failed")
                print(f"  Output: {output[:200]}")  # Show first 200 chars of error
                failure_count += 1

    print(f"\n{'='*60}")
    print(f"Update Summary:")
    print(f"  Successful: {success_count}")
    print(f"  Failed: {failure_count}")
    print(f"  Total: {len(packages)}")
    print(f"{'='*60}")

    sys.exit(0 if failure_count == 0 else 1)


if __name__ == "__main__":
    main()
