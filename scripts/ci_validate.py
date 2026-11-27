#!/usr/bin/env python3
"""Validate tracked server metadata and supported configuration formats."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path

import json5


ROOT = Path(__file__).resolve().parents[1]
SHA1_RE = re.compile(r"^[0-9a-fA-F]{40}$")
COUNT_RE = re.compile(r"共\s*(\d+)\s*个")


class ValidationError(ValueError):
    """Raised when a repository input does not match the expected format."""


@dataclass(frozen=True)
class ModEntry:
    filename: str
    sha1: str
    source: str


def parse_mod_manifest(text: str) -> list[ModEntry]:
    entries: list[ModEntry] = []
    seen: set[str] = set()
    declared_count: int | None = None

    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue

        if line.startswith("#"):
            count_match = COUNT_RE.search(line)
            if count_match:
                declared_count = int(count_match.group(1))
            continue

        fields = [field.strip() for field in line.split("|", maxsplit=2)]
        if len(fields) != 3:
            raise ValidationError(f"line {line_number}: expected filename | SHA1 | source")

        filename, sha1, source = fields
        if (
            not filename.lower().endswith(".jar")
            or Path(filename).name != filename
            or "/" in filename
            or "\\" in filename
        ):
            raise ValidationError(f"line {line_number}: invalid JAR filename {filename!r}")
        if not SHA1_RE.fullmatch(sha1):
            raise ValidationError(f"line {line_number}: invalid SHA1 for {filename!r}")
        if not source:
            raise ValidationError(f"line {line_number}: missing download source for {filename!r}")

        folded_name = filename.casefold()
        if folded_name in seen:
            raise ValidationError(f"line {line_number}: duplicate JAR filename {filename!r}")
        seen.add(folded_name)
        entries.append(ModEntry(filename=filename, sha1=sha1.lower(), source=source))

    if not entries:
        raise ValidationError("mod manifest has no JAR entries")
    if declared_count is not None and declared_count != len(entries):
        raise ValidationError(
            f"manifest declares {declared_count} JARs but contains {len(entries)} entries"
        )
    return entries


def validate_configs() -> tuple[int, int]:
    json_count = 0
    toml_count = 0
    for directory in (ROOT / "config", ROOT / "defaultconfigs", ROOT / "client" / "config"):
        if not directory.exists():
            continue
        for path in directory.rglob("*"):
            if not path.is_file():
                continue
            suffix = path.suffix.lower()
            if suffix not in {".json", ".json5", ".toml"}:
                continue
            try:
                text = path.read_text(encoding="utf-8-sig")
                if suffix in {".json", ".json5"}:
                    json5.loads(text, allow_duplicate_keys=False)
                    json_count += 1
                else:
                    tomllib.loads(text)
                    toml_count += 1
            except (UnicodeError, ValueError) as error:
                relative = path.relative_to(ROOT)
                raise ValidationError(f"{relative}: {error}") from error
    return json_count, toml_count


def validate_workspace(check_local_mods: bool) -> tuple[int, int, int]:
    required_files = (
        ROOT / "start.sh",
        ROOT / "run.sh",
        ROOT / "user_jvm_args.txt",
        ROOT / "server.properties",
        ROOT / "eula.txt",
        ROOT / "mods-manifest.txt",
    )
    missing = [path.relative_to(ROOT) for path in required_files if not path.is_file()]
    if missing:
        raise ValidationError("missing required files: " + ", ".join(map(str, missing)))

    start_script = (ROOT / "start.sh").read_text(encoding="utf-8-sig")
    required_start_references = (
        "@user_jvm_args.txt",
        "@libraries/net/neoforged/neoforge/21.1.267/unix_args.txt",
    )
    for reference in required_start_references:
        if reference not in start_script:
            raise ValidationError(f"start.sh does not reference {reference!r}")

    eula = (ROOT / "eula.txt").read_text(encoding="utf-8-sig")
    if not re.search(r"(?im)^\s*eula\s*=\s*true\s*$", eula):
        raise ValidationError("eula.txt must contain eula=true")

    manifest = parse_mod_manifest((ROOT / "mods-manifest.txt").read_text(encoding="utf-8-sig"))
    if check_local_mods:
        mods_dir = ROOT / "mods"
        if not mods_dir.is_dir():
            raise ValidationError("--check-local-mods requires a local mods/ directory")
        for entry in manifest:
            jar_path = mods_dir / entry.filename
            if not jar_path.is_file():
                raise ValidationError(f"mods/{entry.filename}: file is missing")
            with jar_path.open("rb") as jar_file:
                digest = hashlib.file_digest(jar_file, "sha1").hexdigest()
            if digest != entry.sha1:
                raise ValidationError(f"mods/{entry.filename}: SHA1 mismatch")

    json_count, toml_count = validate_configs()
    return len(manifest), json_count, toml_count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-local-mods",
        action="store_true",
        help="also verify local mods/*.jar files against mods-manifest.txt",
    )
    args = parser.parse_args()

    try:
        jar_count, json_count, toml_count = validate_workspace(args.check_local_mods)
    except (OSError, ValidationError) as error:
        print(f"CI validation failed: {error}", file=sys.stderr)
        return 1

    print(
        f"Validated {jar_count} manifest entries, "
        f"{json_count} JSON files, and {toml_count} TOML files."
    )
    if not args.check_local_mods:
        print("Mod JAR bytes are not present in a clean checkout; local hash checks were not run.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
