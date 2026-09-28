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
"""Prepare the Planetarium's web export in export/ for upload.

Run after exporting the Web preset:

    python web/post_export.py [SUFFIX]

SUFFIX follows "planetarium" in the exported file names and "app" in the name of
the zip this makes for upload: by default the script works on export/planetarium.*
and makes export/app.zip, and with -dev it works on export/planetarium-dev.* and
makes export/app-dev.zip. What it does, and the .htaccess the server needs, are
under *Deploying* in web/README.md. Running it again does no harm.
"""

import gzip
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
EXPORT_DIR = PROJECT_DIR / "export"
EXPORT_NAME = "planetarium"
ZIP_NAME = "app"
SPLASH_IMAGE = PROJECT_DIR / "web" / "pale_blue_dot_453x614.jpg"
HTACCESS = ".htaccess"
HTACCESS_GZIP_LINE = "AddEncoding gzip .gz"
# What an export of the Web preset writes after its name, less the boot-splash
# .png and the two files that get gzipped.
EXPORTED_ENDINGS = (".html", ".js", ".service.worker.js", ".manifest.json", ".offline.html",
        ".icon.png", ".apple-touch-icon.png", ".144x144.png", ".180x180.png", ".512x512.png",
        ".audio.worklet.js", ".audio.position.worklet.js")
GZIPPED_ENDINGS = (".wasm", ".pck")


def main():
    arguments = sys.argv[1:]
    if arguments in (["-h"], ["--help"]):
        print(__doc__)
        return
    if len(arguments) > 1:
        sys.exit(__doc__)
    suffix = arguments[0] if arguments else ""
    name = EXPORT_NAME + suffix
    missing_files = get_missing_files(name)
    if missing_files:
        sys.exit(f"ERROR: {EXPORT_DIR} lacks {', '.join(missing_files)}. Nothing was changed.")
    add_splash_image(name)
    for ending in GZIPPED_ENDINGS:
        gzip_in_place(EXPORT_DIR / (name + ending))
    delete_boot_splash(EXPORT_DIR / (name + ".png"))
    zip_upload(name, EXPORT_DIR / (ZIP_NAME + suffix + ".zip"))


def get_missing_files(name):
    """Return what the upload needs that EXPORT_DIR lacks. A .wasm or .pck already
    gzipped isn't missing."""
    missing_files = []
    for ending in EXPORTED_ENDINGS:
        if not (EXPORT_DIR / (name + ending)).is_file():
            missing_files.append(name + ending)
    for ending in GZIPPED_ENDINGS:
        path = EXPORT_DIR / (name + ending)
        if not path.is_file() and not path.with_name(path.name + ".gz").is_file():
            missing_files.append(path.name)
    htaccess_path = EXPORT_DIR / HTACCESS
    if (not htaccess_path.is_file()
            or HTACCESS_GZIP_LINE not in htaccess_path.read_text(encoding="utf-8")):
        missing_files.append("the .htaccess in web/README.md")
    return missing_files


def add_splash_image(name):
    shutil.copyfile(SPLASH_IMAGE, EXPORT_DIR / SPLASH_IMAGE.name)
    worker_path = EXPORT_DIR / (name + ".service.worker.js")
    with open(worker_path, encoding="utf-8", newline="") as file:
        worker = file.read()
    match = re.search(r"^const CACHED_FILES = (\[.*?\]);", worker, flags=re.MULTILINE)
    if not match:
        sys.exit(f"ERROR: found no CACHED_FILES array in {worker_path}.")
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
    """Replace a file with its gzipped copy, as gzip does, unless that's done already."""
    if not path.is_file():
        print(f"{path.name}: already gzipped")
        return
    gz_path = path.with_name(path.name + ".gz")
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


def zip_upload(name, zip_path):
    """Zip the files the server needs, replacing any earlier zip of that name."""
    file_names = [HTACCESS, SPLASH_IMAGE.name]
    file_names += [name + ending for ending in EXPORTED_ENDINGS]
    file_names += [name + ending + ".gz" for ending in GZIPPED_ENDINGS]
    with zipfile.ZipFile(zip_path, "w") as archive:
        for file_name in file_names:
            # Deflating a .gz again would only cost time.
            compress_type = zipfile.ZIP_STORED if file_name.endswith(".gz") else zipfile.ZIP_DEFLATED
            archive.write(EXPORT_DIR / file_name, file_name, compress_type)
    print(f"{zip_path.name}: {len(file_names)} files, {zip_path.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
