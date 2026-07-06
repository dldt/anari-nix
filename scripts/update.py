#!/usr/bin/env python3

"""
Update script that parses all packages from the flake and runs their update scripts.
For packages with passthru.updateScript, it extracts and runs the update command.
For packages without it, falls back to: nix-update --flake <package-set>.<system>.<package-name>
"""

import json
import os
import shlex
import signal
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Set, Tuple, Union


UPDATE_TIMEOUT_SECONDS = 15 * 60
PROCESS_TERMINATION_GRACE_SECONDS = 5
MAX_FAILURE_OUTPUT_CHARS = 4000

# These packages are intentionally pinned or inherit their source from nixpkgs.
# `nix-update --version=skip` still prefetches and recomputes the source hash; it
# does not skip the package. Avoid that redundant work explicitly instead.
SKIPPED_PACKAGES = {
    "nanovdb-tools": "inherits its source and version from nixpkgs' openvdb",
    "nvidia-optix7": "is intentionally pinned to OptiX 7",
    "nvidia-optix8": "is intentionally pinned to OptiX 8",
    "openvdb-tools": "inherits its source and version from nixpkgs' openvdb",
}


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


def get_current_system() -> Optional[str]:
    """Get the current system platform (e.g., x86_64-linux, aarch64-darwin)."""
    output = run_nix_eval(["--impure", "--expr", "builtins.currentSystem"])
    if output:
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return None
    return None


def get_all_packages(flake_path: str, system: str) -> Optional[List[str]]:
    """
    Get all packages from the flake for the current system.
    Returns a list of package names.
    """
    output = run_nix_eval(
        [
            "--accept-flake-config",
            f"{flake_path}#packages.{system}",
        ]
    )

    if output is None:
        return None

    try:
        packages = json.loads(output)
        return list(packages.keys())
    except (json.JSONDecodeError, AttributeError) as e:
        print(f"Error parsing packages.{system}: {e}", file=sys.stderr)
        return None


def get_update_script(
    flake_path: str, system: str, package_name: str
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
                f"{flake_path}#packages.{system}.{package_name}.passthru.updateScript",
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


def get_all_package_names(flake_path: str) -> Set[str]:
    """
    Get all package names across all systems to detect packages not available on current platform.
    Returns a set of all unique package names.
    """
    output = run_nix_eval(
        [
            "--accept-flake-config",
            f"{flake_path}#packages",
        ]
    )

    if output is None:
        return set()

    try:
        packages_by_system = json.loads(output)
        all_names = set()
        for system, system_packages in packages_by_system.items():
            all_names.update(system_packages.keys())
        return all_names
    except (json.JSONDecodeError, AttributeError):
        return set()


def get_fallback_command(package_name: str) -> List[str]:
    """Get the fallback update command for a package."""
    return ["nix-update", "--flake", package_name]


def get_package_source_path(
    flake_path: str, system: str, package_name: str
) -> Optional[str]:
    """
    Get the source directory path for a package.
    Returns the directory path or the package name as fallback.
    """
    try:
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--json",
                "--accept-flake-config",
                f"{flake_path}#packages.{system}.{package_name}.meta.position",
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


def prepare_update_tasks(
    flake_path: str, system: str, package_names: List[str]
) -> Tuple[List[Tuple[str, List[str]]], List[Tuple[str, str]]]:
    """Build serialized update tasks and collect explicitly skipped packages."""
    update_tasks = []
    skipped_packages = []

    for package_name in sorted(package_names):
        if reason := SKIPPED_PACKAGES.get(package_name):
            skipped_packages.append((package_name, reason))
            continue

        update_script = get_update_script(flake_path, system, package_name)
        if update_script is not None:
            command = update_script + [package_name]
        else:
            command = get_fallback_command(package_name)

        update_tasks.append((package_name, command))

    return update_tasks, skipped_packages


def decode_output(output: Optional[Union[str, bytes]]) -> str:
    """Normalize subprocess output, including TimeoutExpired byte output."""
    if output is None:
        return ""
    if isinstance(output, bytes):
        return output.decode(errors="replace")
    return output


def format_duration(seconds: float) -> str:
    """Format a timeout duration for user-facing messages."""
    if seconds >= 60 and seconds % 60 == 0:
        minutes = int(seconds // 60)
        unit = "minute" if minutes == 1 else "minutes"
        return f"{minutes} {unit}"
    return f"{seconds:g} seconds"


def terminate_process_group(
    process: subprocess.Popen[str], grace_seconds: float
) -> str:
    """Terminate a timed-out updater and every child in its process group."""
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass

    try:
        output, _ = process.communicate(timeout=grace_seconds)
        return decode_output(output)
    except subprocess.TimeoutExpired as error:
        partial_output = decode_output(error.output)

    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass

    output, _ = process.communicate()
    return decode_output(output) or partial_output


def run_update(
    package_name: str,
    command: List[str],
    flake_path: str,
    timeout_seconds: float = UPDATE_TIMEOUT_SECONDS,
    termination_grace_seconds: float = PROCESS_TERMINATION_GRACE_SECONDS,
) -> Tuple[str, bool, str]:
    """
    Run the update command for a package.
    Returns (package_name, success, output).
    """
    cmd_str = shlex.join(command)
    print(f"Updating {package_name}: {cmd_str}")

    process = subprocess.Popen(
        command,
        cwd=flake_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        start_new_session=True,
    )

    try:
        output, _ = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired as error:
        partial_output = decode_output(error.output)
        terminated_output = terminate_process_group(process, termination_grace_seconds)
        output = terminated_output or partial_output
        message = f"Update timed out after {format_duration(timeout_seconds)}."
        if output.strip():
            message += f"\nPartial output:\n{output.rstrip()}"
        return (package_name, False, message)

    output = decode_output(output)
    if process.returncode != 0:
        message = f"Update exited with status {process.returncode}."
        if output.strip():
            message += f"\n{output.rstrip()}"
        return (package_name, False, message)

    return (package_name, True, output)


def print_failure_output(output: str) -> None:
    """Print the useful tail of updater output without flooding CI logs."""
    output = output.strip() or "(no output)"
    if len(output) > MAX_FAILURE_OUTPUT_CHARS:
        output = (
            f"[truncated to last {MAX_FAILURE_OUTPUT_CHARS} characters]\n"
            f"{output[-MAX_FAILURE_OUTPUT_CHARS:]}"
        )

    print("  Output:")
    for line in output.splitlines():
        print(f"    {line}")


def configure_output_buffering() -> None:
    """Make progress visible immediately when stdout is redirected by CI."""
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(line_buffering=True)


def main():
    configure_output_buffering()

    # Get the flake directory (parent of scripts directory)
    script_dir = Path(__file__).resolve().parent
    flake_dir = script_dir.parent
    flake_path = str(flake_dir)

    # Get current system platform
    print("Detecting current system platform...")
    current_system = get_current_system()
    if not current_system:
        print("Failed to detect current system platform", file=sys.stderr)
        sys.exit(1)
    print(f"Current system: {current_system}")

    # Get all package names across all systems for comparison
    print(f"\nFinding all packages in flake at {flake_path}...")
    all_package_names = get_all_package_names(flake_path)

    # Get packages for current system only
    print(f"Finding packages for {current_system}...")
    current_packages = get_all_packages(flake_path, current_system)

    if current_packages is None:
        print(f"Failed to get package list for {current_system}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(current_packages)} packages for {current_system}")

    # Warn about packages not available on current platform
    current_package_set = set(current_packages)
    unavailable_packages = all_package_names - current_package_set
    if unavailable_packages:
        print(
            f"\n⚠️  WARNING: {len(unavailable_packages)} package(s) not available on {current_system}:"
        )
        for pkg in sorted(unavailable_packages):
            print(f"  - {pkg}")
        print(f"These packages will NOT be updated.\n")

    update_tasks, skipped_packages = prepare_update_tasks(
        flake_path, current_system, current_packages
    )

    if skipped_packages:
        print(f"\nSkipping {len(skipped_packages)} explicitly excluded package(s):")
        for package_name, reason in skipped_packages:
            print(f"  - {package_name}: {reason}")

    print(
        f"\nStarting serialized updates for {len(update_tasks)} packages "
        f"({format_duration(UPDATE_TIMEOUT_SECONDS)} timeout per package)...\n"
    )

    success_count = 0
    failure_count = 0
    failed_packages = []

    for package_name, command in update_tasks:
        _, success, output = run_update(package_name, command, flake_path)
        if success:
            print(f"✓ {package_name}: Success")
            success_count += 1
        else:
            print(f"✗ {package_name}: Failed")
            print_failure_output(output)
            failure_count += 1
            failed_packages.append((package_name, command))

    print(f"\n{'='*60}")
    print(f"Update Summary:")
    print(f"  Platform: {current_system}")
    print(f"  Successful: {success_count}")
    print(f"  Failed: {failure_count}")
    print(f"  Attempted: {len(update_tasks)} packages")
    if skipped_packages:
        print(f"  Skipped (configured): {len(skipped_packages)}")
    if unavailable_packages:
        print(f"  Skipped (unavailable): {len(unavailable_packages)}")
    if failed_packages:
        print(f"\nFailed packages:")
        for pkg_name, cmd in sorted(failed_packages):
            cmd_str = shlex.join(cmd)
            print(f"  - {pkg_name}")
            print(f"    Command: {cmd_str}")
    print(f"{'='*60}")

    sys.exit(0 if failure_count == 0 else 1)


if __name__ == "__main__":
    main()
