#!/usr/bin/env python3

"""
Update script that parses all packages from the flake and runs their update scripts.
For packages with passthru.updateScript, it extracts and runs the update command.
For packages without it, falls back to: nix-update --flake <package-set>.<system>.<package-name>
"""

import json
import subprocess
import sys
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


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


def discover_package_sets(flake_path: str) -> List[str]:
    """Return the standard 'packages' output."""
    return ["packages"]


def get_all_packages(
    flake_path: str, package_sets: List[str]
) -> Optional[List[Tuple[str, str, str]]]:
    """
    Get all packages from the flake across all package sets and systems.
    Returns a list of tuples: (package_set, system, package_name)
    """
    all_packages = []

    for package_set in package_sets:
        output = run_nix_eval(
            [
                "--accept-flake-config",
                f"{flake_path}#{package_set}",
            ]
        )

        if output is None:
            continue

        try:
            packages_by_system = json.loads(output)
            # Keep the structure: package_set.system.package_name
            for system, system_packages in packages_by_system.items():
                for package_name in system_packages.keys():
                    all_packages.append((package_set, system, package_name))
        except (json.JSONDecodeError, AttributeError) as e:
            print(f"Error parsing {package_set}: {e}", file=sys.stderr)
            continue

    return all_packages if all_packages else None


def get_update_script(
    flake_path: str, package_set: str, system: str, package_name: str
) -> Optional[List[str]]:
    """
    Get the update script for a package.
    Returns the command as a list of arguments, or None if no updateScript exists.
    """
    try:
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--json",
                "--accept-flake-config",
                f"{flake_path}#{package_set}.{system}.{package_name}.passthru.updateScript",
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,  # Suppress errors when attribute doesn't exist
            text=True,
        )
        output = result.stdout
    except subprocess.CalledProcessError:
        # Attribute doesn't exist
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


def get_fallback_command(package_set: str, system: str, package_name: str) -> List[str]:
    """Get the fallback update command for a package."""
    return ["nix-update", "--flake", f"{package_set}.{system}.{package_name}"]


def get_package_source_path(
    flake_path: str, package_set: str, system: str, package_name: str
) -> Optional[str]:
    """
    Get the source directory path for a package.
    This is used to deduplicate packages that appear in multiple platforms/package-sets.
    """
    try:
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--json",
                "--accept-flake-config",
                f"{flake_path}#{package_set}.{system}.{package_name}.meta.position",
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        position = json.loads(result.stdout)
        # Position is like "/path/to/pkgs/package-name/package.nix:line:col"
        # Extract the directory path
        if ":" in position:
            file_path = position.split(":")[0]
            return str(Path(file_path).parent)
        return None
    except (subprocess.CalledProcessError, json.JSONDecodeError, AttributeError):
        # Fallback: use package name as identifier
        return package_name


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

    print(f"Discovering package sets in flake at {flake_path}...")
    package_sets = discover_package_sets(flake_path)

    if not package_sets:
        print("Failed to discover package sets", file=sys.stderr)
        sys.exit(1)

    print(f"Found package sets: {', '.join(package_sets)}")

    print(f"\nFinding packages in all package sets...")
    all_packages = get_all_packages(flake_path, package_sets)

    if all_packages is None:
        print("Failed to get package list", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(all_packages)} package instances across all sets and systems")

    # Deduplicate packages by their source path to avoid concurrent updates
    # Group by source path: {source_path: [(package_set, system, package_name), ...]}
    packages_by_source: Dict[str, List[Tuple[str, str, str]]] = defaultdict(list)

    for package_set, system, package_name in all_packages:
        source_path = get_package_source_path(
            flake_path, package_set, system, package_name
        )
        if source_path:
            packages_by_source[source_path].append((package_set, system, package_name))

    print(f"Deduplicated to {len(packages_by_source)} unique packages")

    # Prepare update commands for unique packages
    # Use the first occurrence of each package for the update
    update_tasks = []
    for source_path, package_instances in packages_by_source.items():
        # Pick the first instance to use for updating
        package_set, system, package_name = package_instances[0]

        # Build a display name showing all platforms this package appears in
        platforms = [f"{ps}.{sys}" for ps, sys, _ in package_instances]
        display_name = f"{package_name} ({', '.join(platforms)})"

        # Try to get the update script from passthru
        update_script = get_update_script(flake_path, package_set, system, package_name)

        if update_script is not None:
            # Append the full attribute path to the update script
            command = update_script + [f"{package_set}.{system}.{package_name}"]
        else:
            # Fall back to nix-update with full attribute path
            command = get_fallback_command(package_set, system, package_name)

        update_tasks.append((display_name, command))

    print(f"\nStarting updates (running up to 4 in parallel)...")

    # Run updates in parallel
    success_count = 0
    failure_count = 0
    failed_packages = []

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {
            executor.submit(run_update, pkg, cmd, flake_path): (pkg, cmd)
            for pkg, cmd in update_tasks
        }

        for future in as_completed(futures):
            package_name, success, output = future.result()
            pkg_name, cmd = futures[future]
            if success:
                print(f"✓ {package_name}: Success")
                success_count += 1
            else:
                print(f"✗ {package_name}: Failed")
                print(f"  Output: {output[:200]}")  # Show first 200 chars of error
                failure_count += 1
                failed_packages.append((package_name, cmd))

    print(f"\n{'='*60}")
    print(f"Update Summary:")
    print(f"  Successful: {success_count}")
    print(f"  Failed: {failure_count}")
    print(f"  Total: {len(packages_by_source)} unique packages")
    if failed_packages:
        print(f"\nFailed packages:")
        for pkg_name, cmd in sorted(failed_packages):
            cmd_str = " ".join(cmd)
            print(f"  - {pkg_name}")
            print(f"    Command: {cmd_str}")
    print(f"{'='*60}")

    sys.exit(0 if failure_count == 0 else 1)


if __name__ == "__main__":
    main()
