#!/bin/bash
# backup.bash: copy one or more BG3 mod folders and store them in a repo; if one mod then repo/<subdir>/..., else repo/<modname>/<subdir>/...
# derived by TheCobaltCactus from original code by mstephenson6, see guide at https://mod.io/g/baldursgate3/r/git-backups-for-mod-projects
set -e

#TODO: Set list of mod folder(s) here
MOD_SUBDIRS=(
  "notable_guardians_a8abde8c-60f3-1306-0d2e-1fed719dd38e"
  "notable_guardians_2_f4732d93-9bd1-07ea-701a-0b159587eb84"
)

#set this to your BG3/data folder path
BG3_DATA="/d/Program Files (x86)/Steam/steamapps/common/Baldurs Gate 3/Data"
# Look in "D:\Program Files (x86)\Steam\steamapps\common\Baldurs Gate 3\Data\"
# for names of mods you have already started

SUBDIR_LIST=(
  "Projects"
  "Editor/Mods"
  "Mods"
  "Public"
  "Generated/Public"
)

#!/bin/bash
# backup.bash: copy BG3 mod folders; if one mod then repo/<subdir>/..., else repo/<modname>/<subdir>/...
set -e

MOD_SUBDIRS=(
  "notable_guardians_a8abde8c-60f3-1306-0d2e-1fed719dd38e"
  "notable_guardians_2_f4732d93-9bd1-07ea-701a-0b159587eb84"
  # add more names as needed
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
  echo "MOD_SUBDIRS must contain at least one folder name in $(basename "$BASH_SOURCE")"
  exit 1
fi

single_mod=false
if [ ${#MOD_SUBDIRS[@]} -eq 1 ]; then
  single_mod=true
  single_name="${MOD_SUBDIRS[0]}"
fi

for modname in "${MOD_SUBDIRS[@]}"; do
  found_any=false

  for subdir in "${SUBDIR_LIST[@]}"; do
    src="$BG3_DATA/$subdir/$modname"

    if [ "$single_mod" = true ]; then
      dest="$subdir"                    # repo/<subdir>/...
    else
      dest="$modname/$subdir"           # repo/<modname>/<subdir>/...
    fi

    if [ -d "$src" ]; then
      found_any=true
      mkdir -p "$(dirname "$dest")"
      # remove existing destination to ensure sync
      rm -rf "$dest"
      cp -a "$src" "$dest"
    fi
  done

  if [ "$found_any" = false ]; then
    echo "Warning: mod '$modname' not found in any SUBDIR_LIST locations."
    if [ "$single_mod" = true ]; then
      rmdir --ignore-fail-on-non-empty "$single_name" 2>/dev/null || true
    else
      rmdir --ignore-fail-on-non-empty "$modname" 2>/dev/null || true
    fi
  fi
done

git add --all
git commit -m "Backup at $(date)"
git push