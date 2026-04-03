#!/bin/bash
set -euo pipefail

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

# helper: create zip of a directory list using zip or Python fallback
zip_paths() {
  local dst_zip="$1"; shift
  rm -f "$dst_zip"
  if command -v zip >/dev/null 2>&1; then
    # zip from repo root: include each source path with the desired archive name
    zip -r -0 "$dst_zip" "$@" >/dev/null
  else
    # Python fallback: expects pairs of (source_dir, archive_prefix) flattened as args
    python - "$tmpdir" "$zippath" <<'PYCODE'
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

ZIP_ROOT="."

for modname in "${MOD_SUBDIRS[@]}"; do
  found_any=false
  # collect args for Python fallback (dst + pairs) or zip include list (prefixing will be handled below)
  # For zip CLI, we'll create temporary symlinked paths under a temp dir to control archive paths.
  tmpdir="$(mktemp -d)"
  cleanup() { rm -rf "$tmpdir"; }
  trap cleanup RETURN

  # For zip CLI path list: we will copy directory trees into tmpdir under subdir-prefixed folders
  for subdir in "${SUBDIR_LIST[@]}"; do
    src_dir="$BG3_DATA/$subdir/$modname"
    if [ ! -d "$src_dir" ]; then
      continue
    fi
    found_any=true
    # create a directory inside tmpdir named like <safe_sub>/<original files...>
    safe_sub="${subdir//\//_}"
    dest_under_tmp="$tmpdir/$safe_sub"
    mkdir -p "$dest_under_tmp"
    # Copy contents (preserve tree inside safe_sub)
    cp -a "$src_dir/." "$dest_under_tmp/" || true
  done

  if [ "$found_any" = false ]; then
    echo "Warning: mod '$modname' not found in any SUBDIR_LIST locations."
    continue
  fi

  zipname="${modname}.zip"
  zippath="$ZIP_ROOT/$zipname"

  echo "Creating root zip $zippath for mod $modname"
  if command -v zip >/dev/null 2>&1; then
    (cd "$tmpdir" && zip -r -0 "$zippath" .) >/dev/null
  else
    # Use Python fallback: we created a tmpdir with desired archive layout already
    python - "$tmpdir" "$zippath" <<'PYCODE'
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

done

git add --all
git commit -m "Backup at $(date)"
git push