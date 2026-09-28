# post_export.py
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield in the US
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************
"""Prepare the Planetarium's web export for upload.

Run after exporting the Web preset:

    python web/post_export.py [EXPORTED_HTML]

EXPORTED_HTML defaults to the Web preset's export_path in export_presets.cfg.
What the script does to the export, and the .htaccess the server then needs, are
under *Deploying* in web/README.md. Running it again changes nothing.
"""

import argparse
import gzip
import json
import re
import shutil
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
SPLASH_IMAGE = PROJECT_DIR / "web" / "pale_blue_dot_453x614.jpg"
GZIPPED_SUFFIXES = (".wasm", ".pck")
HTACCESS_GZIP_LINE = "AddEncoding gzip .gz"


def main():
    parser = argparse.ArgumentParser(
            description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("exported_html", nargs="?", type=Path,
            help="the exported .html (default: the Web preset's export_path)")
    args = parser.parse_args()
    html_path = args.exported_html or get_web_export_path()
    if not html_path.is_file():
        sys.exit(f"No exported page at {html_path}.")
    export_dir = html_path.parent
    name = html_path.stem
    add_splash_image(export_dir, name)
    for suffix in GZIPPED_SUFFIXES:
        gzip_in_place(export_dir / (name + suffix))
    delete_boot_splash(export_dir / (name + ".png"))
    check_htaccess(export_dir)


def get_web_export_path():
    """Return the Web preset's export_path from export_presets.cfg."""
    presets = (PROJECT_DIR / "export_presets.cfg").read_text(encoding="utf-8")
    for section in re.split(r"^\[", presets, flags=re.MULTILINE):
        if not re.search(r'^platform="Web"$', section, flags=re.MULTILINE):
            continue
        match = re.search(r'^export_path="(.+)"$', section, flags=re.MULTILINE)
        if match:
            return PROJECT_DIR / match.group(1)
    sys.exit("export_presets.cfg has no Web preset with an export_path. Name the exported .html.")


def add_splash_image(export_dir, name):
    shutil.copyfile(SPLASH_IMAGE, export_dir / SPLASH_IMAGE.name)
    worker_path = export_dir / (name + ".service.worker.js")
    if not worker_path.is_file():
        sys.exit(f"No service worker at {worker_path}. Is the preset's Progressive Web App on?")
    with open(worker_path, encoding="utf-8", newline="") as file:
        worker = file.read()
    match = re.search(r"^const CACHED_FILES = (\[.*?\]);", worker, flags=re.MULTILINE)
    if not match:
        sys.exit(f"Found no CACHED_FILES array in {worker_path}.")
    cached_files = json.loads(match.group(1))
    if SPLASH_IMAGE.name in cached_files:
        print(f"{worker_path.name}: CACHED_FILES already has {SPLASH_IMAGE.name}")
        return
    cached_files.append(SPLASH_IMAGE.name)
    # Godot writes the array as compact JSON.
    cached_files_json = json.dumps(cached_files, separators=(",", ":"))
    worker = worker[:match.start(1)] + cached_files_json + worker[match.end(1):]
    with open(worker_path, "w", encoding="utf-8", newline="") as file:
        file.write(worker)
    print(f"{worker_path.name}: added {SPLASH_IMAGE.name} to CACHED_FILES")


def gzip_in_place(path):
    """Replace a file with its gzipped copy, as gzip does."""
    gz_path = path.with_name(path.name + ".gz")
    if not path.is_file():
        if not gz_path.is_file():
            sys.exit(f"Found neither {path} nor {gz_path}.")
        print(f"{path.name}: already gzipped")
        return
    with open(path, "rb") as source, gzip.open(gz_path, "wb", compresslevel=9) as target:
        shutil.copyfileobj(source, target, 1 << 20)
    size = path.stat().st_size
    path.unlink()
    print(f"{path.name}: {size / 1e6:.1f} MB -> {gz_path.name}: {gz_path.stat().st_size / 1e6:.1f} MB")


def delete_boot_splash(path):
    if not path.is_file():
        return
    path.unlink()
    print(f"{path.name}: deleted")


def check_htaccess(export_dir):
    htaccess_path = export_dir / ".htaccess"
    if htaccess_path.is_file() and HTACCESS_GZIP_LINE in htaccess_path.read_text(encoding="utf-8"):
        return
    print(f"WARNING: no .htaccess in {export_dir} serves the .gz files, and without one the"
            " server has no .wasm or .pck to send. Use the one in web/README.md.")


if __name__ == "__main__":
    main()
