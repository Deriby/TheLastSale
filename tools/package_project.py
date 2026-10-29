"""Build the portable Godot project ZIP; keep engine caches and exports outside it."""
from pathlib import Path
import argparse
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parent.parent
VERSION = "0.17.0"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "downloads/project" / f"TheLastSale_Godot_{VERSION}.zip")
    args = parser.parse_args()
    sources = {}
    for folder in ["assets", "scenes", "scripts", "resources", "shaders", "tools", "tests"]:
        for path in sorted((ROOT / folder).rglob("*")):
            if not path.is_file():
                continue
            relative = path.relative_to(ROOT)
            if relative.is_relative_to("assets/models/originals"):
                continue
            if "__pycache__" in relative.parts or path.name.endswith(".blend1"):
                continue
            sources[relative.as_posix()] = path
    for name in ["project.godot", "export_presets.cfg", ".gitignore",
                 "docs/.gdignore", "docs/user_models_report.json", "docs/PENDENCIAS.md", "docs/surface_report.json"]:
        sources[name] = ROOT / name
    for gallery in ["optimization_v011", "checkout_v017"]:
        for path in sorted((ROOT / "docs" / gallery).rglob("*")):
            if path.is_file():
                sources[path.relative_to(ROOT).as_posix()] = path
    sources["README.md"] = ROOT / "tools/project_archive_readme.md"
    records = {name: {"bytes": path.stat().st_size,
                       "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
               for name, path in sorted(sources.items())}
    manifest = {"project": "Deriby/TheLastSale", "version": VERSION,
                "godot": "4.4.1", "entry": "project.godot", "files": records}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, path in sorted(sources.items()):
            info = zipfile.ZipInfo("TheLastSale/" + name, date_time=(2026, 10, 29, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (0o100755 if name.endswith(".sh") else 0o100644) << 16
            archive.writestr(info, path.read_bytes(), compresslevel=9)
        archive.writestr("TheLastSale/PROJETO_MANIFESTO.json",
                         json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    with zipfile.ZipFile(args.output) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError("CRC failure: " + bad)
        for name, record in records.items():
            actual = hashlib.sha256(archive.read("TheLastSale/" + name)).hexdigest()
            if actual != record["sha256"]:
                raise RuntimeError("Packaged file mismatch: " + name)
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    args.output.with_suffix(".sha256").write_text(digest + "  " + args.output.name + "\n")
    print(json.dumps({"path": str(args.output), "bytes": args.output.stat().st_size,
                      "files": len(records), "sha256": digest}, indent=2))


if __name__ == "__main__":
    main()
