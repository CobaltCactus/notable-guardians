#!/bin/bash
set -euo pipefail

# TODO: set mod folder(s) here
MOD_SUBDIRS=(
  "notable_guardians_a8abde8c-60f3-1306-0d2e-1fed719dd38e"
  "notable_guardians_2_f4732d93-9bd1-07ea-701a-0b159587eb84"
)

BG3_DATA="/d/Program Files (x86)/Steam/steamapps/common/Baldurs Gate 3/Data"

SUBDIR_LIST=(
  "Projects"
  "Editor/Mods"
  "Mods"
  "Public"
  "Generated/Public"
)

if [ ${#MOD_SUBDIRS[@]} -eq 0 ]; then
  echo "MOD_SUBDIRS must contain at least one folder name in $(basename "$0")"
  exit 1
fi

single_mod=false
if [ ${#MOD_SUBDIRS[@]} -eq 1 ]; then
  single_mod=true
fi

# helper: create zip of a directory using zip or Python fallback
zip_dir() {
  local src="$1" dest_zip="$2"
  rm -f "$dest_zip"
  if command -v zip >/dev/null 2>&1; then
    (cd "$src" && zip -r -0 "$OLDPWD/$dest_zip" .) >/dev/null
  else
    # Python fallback (works if python is available)
    python - "$src" "$dest_zip" <<'PYCODE'
import sys, os, zipfile
src = sys.argv[1]
dst = sys.argv[2]
with zipfile.ZipFile(dst, 'w', compression=zipfile.ZIP_STORED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            arc = os.path.relpath(full, src)
            zf.write(full, arc)
PYCODE
  fi
}

# Root where zip files will be placed (current directory). Change if you want a specific root folder.
ZIP_ROOT="."

for modname in "${MOD_SUBDIRS[@]}"; do
  found_any=false

  for subdir in "${SUBDIR_LIST[@]}"; do
    src_dir="$BG3_DATA/$subdir/$modname"
    if [ ! -d "$src_dir" ]; then
      continue
    fi

    found_any=true

    if [ "$single_mod" = true ]; then
      target_dir="$subdir/$modname"
      mkdir -p "$subdir"
    else
      target_dir="$modname/$subdir/$modname"
      mkdir -p "$modname/$subdir"
    fi

    # Ensure target_dir exists and is empty
    mkdir -p "$target_dir"
    rm -rf "$target_dir/"*

    # Create a compact zip name (replace slashes with underscores).
    # Put the zip at the repo root (ZIP_ROOT). Use a name that reflects original location to avoid collisions.
    safe_sub="${subdir//\//_}"
    zipname="${safe_sub}_${modname}.zip"
    zippath="$ZIP_ROOT/$zipname"

    echo "Zipping $src_dir -> $zippath"
    zip_dir "$src_dir" "$zippath"

    # If you still need a copy of the zip inside the target_dir, uncomment the next line:
    # cp "$zippath" "$target_dir/"
  done

  if [ "$found_any" = false ]; then
    echo "Warning: mod '$modname' not found in any SUBDIR_LIST locations."
    rmdir --ignore-fail-on-non-empty "$modname" 2>/dev/null || true
  fi
done

git add --all
git commit -m "Backup at $(date)"
git push