#!/usr/bin/env python3
"""
package_skill.py — Package an FS25 Claude skill folder into a .skill zip file.

Usage:
    python package_skill.py fs25-modding-skill/
    python package_skill.py fs25-modding-skill/ --output ../releases/

Output: fs25-modding.skill (a zip file Claude can load)
"""

import argparse
import os
import sys
import zipfile
from pathlib import Path


def package_skill(skill_dir: str, output_dir: str = ".") -> Path:
    skill_path = Path(skill_dir).resolve()
    
    if not skill_path.is_dir():
        print(f"ERROR: {skill_path} is not a directory", file=sys.stderr)
        sys.exit(1)
    
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"ERROR: No SKILL.md found in {skill_path}", file=sys.stderr)
        sys.exit(1)
    
    # Derive output filename from directory name
    skill_name = skill_path.name
    output_path = Path(output_dir) / f"{skill_name}.skill"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    file_count = 0
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for file_path in sorted(skill_path.rglob('*')):
            if file_path.is_file():
                # Store relative to the skill directory
                arcname = file_path.relative_to(skill_path.parent)
                zf.write(file_path, arcname)
                file_count += 1
                print(f"  + {arcname}")
    
    size_kb = output_path.stat().st_size / 1024
    print(f"\n✅ Packaged {file_count} files → {output_path} ({size_kb:.1f} KB)")
    return output_path


def main():
    parser = argparse.ArgumentParser(description="Package a Claude skill into a .skill file")
    parser.add_argument("skill_dir", help="Path to the skill folder (must contain SKILL.md)")
    parser.add_argument("--output", "-o", default=".", help="Output directory (default: current dir)")
    args = parser.parse_args()
    
    package_skill(args.skill_dir, args.output)


if __name__ == "__main__":
    main()
