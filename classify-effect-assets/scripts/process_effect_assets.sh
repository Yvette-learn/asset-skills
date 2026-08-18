#!/usr/bin/env bash
set -euo pipefail

need="/mnt/d/need"
git_bash="/mnt/c/Program Files/Git/bin/bash.exe"
effect=""
decrypt_first=""
execute=0
paths=()

usage() {
  cat <<'USAGE'
Usage:
  process_effect_assets.sh --effect VALUE --decrypt-first always|never [--need-dir /mnt/d/need] [--git-bash PATH] [--execute] -- DIR...

Without --execute, the script only reports counts and planned operations.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --effect)
      effect="${2:-}"
      shift 2
      ;;
    --decrypt-first)
      decrypt_first="${2:-}"
      shift 2
      ;;
    --need-dir)
      need="${2:-}"
      shift 2
      ;;
    --git-bash)
      git_bash="${2:-}"
      shift 2
      ;;
    --execute)
      execute=1
      shift
      ;;
    --)
      shift
      paths=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      paths+=("$1")
      shift
      ;;
  esac
done

if [ -z "$effect" ]; then
  echo "ERROR: --effect is required and must be provided by the user for each run." >&2
  exit 2
fi

case "$effect" in
  *"'"*|*$'\n'*)
    echo "ERROR: --effect must not contain single quotes or newlines." >&2
    exit 2
    ;;
esac

if [ "$decrypt_first" != "always" ] && [ "$decrypt_first" != "never" ]; then
  echo "ERROR: --decrypt-first must be always or never." >&2
  exit 2
fi

if [ "${#paths[@]}" -eq 0 ]; then
  echo "ERROR: provide at least one asset directory." >&2
  exit 2
fi

to_wsl_path() {
  local path="$1"
  if [[ "$path" =~ ^/([A-Za-z])(/.*)?$ ]]; then
    local drive="${BASH_REMATCH[1],,}"
    local rest="${BASH_REMATCH[2]:-}"
    printf '/mnt/%s%s\n' "$drive" "$rest"
  else
    printf '%s\n' "$path"
  fi
}

to_git_path() {
  local path="$1"
  if [[ "$path" =~ ^/mnt/([A-Za-z])(/.*)?$ ]]; then
    local drive="${BASH_REMATCH[1],,}"
    local rest="${BASH_REMATCH[2]:-}"
    printf '/%s%s\n' "$drive" "$rest"
  else
    printf '%s\n' "$path"
  fi
}

need="$(to_wsl_path "$need")"
need_git="$(to_git_path "$need")"

decrypt="$need/decrypt"
jiemi="$need/jiemi"
encrypt="$need/encrypt"
short_bat="$need/批处理文件改.bat"
run_bash="$need/run_bash.sh"

for required in "$need" "$short_bat" "$run_bash" "$git_bash"; do
  if [ ! -e "$required" ]; then
    echo "ERROR: required path not found: $required" >&2
    exit 3
  fi
done

count_images() {
  find "$1" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | wc -l
}

count_zips() {
  find "$1" -maxdepth 1 -type f -name '*.zip' | wc -l
}

if [ "$execute" -eq 0 ]; then
  echo "DRY_RUN effect=$effect decrypt_first=$decrypt_first need=$need git_bash=$git_bash"
  for src in "${paths[@]}"; do
    if [ ! -d "$src" ]; then
      echo "MISSING_DIR $src"
      continue
    fi
    echo "PLAN ${src##*/}: zip=$(count_zips "$src") image=$(count_images "$src")"
  done
  exit 0
fi

for src in "${paths[@]}"; do
  if [ ! -d "$src" ]; then
    echo "ERROR: directory not found: $src" >&2
    exit 4
  fi

  name="${src##*/}"
  before_zip=$(count_zips "$src")
  before_img=$(count_images "$src")

  if [ "$before_zip" -eq 0 ]; then
    echo "SKIP $name: no zip files"
    continue
  fi

  win_src="$(wslpath -w "$src")"
  short_bat_win="$(wslpath -w "$short_bat")"
  printf '\n' | cmd.exe /c "cd /d $win_src && $short_bat_win" >/tmp/effect_shortname_"$name".log 2>&1

  rm -rf "$decrypt" "$jiemi" "$encrypt"
  mkdir -p "$decrypt"

  for z in "$src"/*.zip; do
    [ -e "$z" ] || continue
    cp -p "$z" "$decrypt/"
  done

  if [ "$decrypt_first" = "always" ]; then
    (
      "$git_bash" -lc "cd '$need_git' && bash run_bash.sh -d -i ./decrypt -o ./jiemi"
    ) >/tmp/effect_decrypt_"$name".log 2>&1

    rm -rf "$decrypt"
    mkdir -p "$decrypt"
    dec_count=0
    for z in "$jiemi"/de_*.zip; do
      [ -e "$z" ] || continue
      base="${z##*/}"
      cp -p "$z" "$decrypt/${base#de_}"
      dec_count=$((dec_count + 1))
    done
    if [ "$dec_count" -ne "$before_zip" ]; then
      echo "ERROR: decrypt count mismatch for $name: expected $before_zip got $dec_count" >&2
      cat /tmp/effect_decrypt_"$name".log >&2
      exit 5
    fi
  fi

  (
    "$git_bash" -lc "cd '$need_git' && bash run_bash.sh -e -i ./decrypt -o ./encrypt '-effect $effect'"
  ) >/tmp/effect_encrypt_"$name".log 2>&1

  enc_count=0
  for z in "$encrypt"/en_*.zip; do
    [ -e "$z" ] || continue
    base="${z##*/}"
    cp -p "$z" "$src/${base#en_}"
    enc_count=$((enc_count + 1))
  done

  if [ "$enc_count" -ne "$before_zip" ]; then
    echo "ERROR: encrypt count mismatch for $name: expected $before_zip got $enc_count" >&2
    cat /tmp/effect_encrypt_"$name".log >&2
    exit 6
  fi

  after_zip=$(count_zips "$src")
  after_img=$(count_images "$src")
  remaining_long=$(find "$src" -maxdepth 1 -type f \( -name '*_*.zip' -o -name '*_*.png' -o -name '*_*.jpg' -o -name '*_*.jpeg' -o -name '*_*.webp' \) | wc -l)
  success_count=$(grep -c 'Success' /tmp/effect_encrypt_"$name".log || true)

  echo "OK $name: zip $before_zip->$after_zip image $before_img->$after_img encrypted=$success_count remaining_long=$remaining_long"
done

rm -rf "$decrypt" "$jiemi" "$encrypt"
mkdir -p "$decrypt" "$encrypt"
