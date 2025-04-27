#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Использование:
  $0 INPUT_DIR OUTPUT_DIR [--max_depth N]

  INPUT_DIR    — исходная директория
  OUTPUT_DIR   — директория для копирования
  --max_depth N — сохранять структуру каталогов до глубины N (сам INPUT_DIR = 0)
EOF
  exit 1
}

if (( $# < 2 )); then
  usage
fi

input_dir="$1"
output_dir="$2"
shift 2

max_depth_mode=false
max_depth=0

while (( $# > 0 )); do
  case "$1" in
    --max_depth)
      if (( $# < 2 )); then
        echo "Ошибка: после --max_depth должно идти число" >&2
        exit 1
      fi
      max_depth_mode=true
      max_depth="$2"
      if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: глубина должна быть неотрицательным целым числом" >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Неизвестный параметр: $1" >&2
      usage
      ;;
  esac
done

if [ ! -d "$input_dir" ]; then
  echo "Ошибка: входная директория '$input_dir' не существует" >&2
  exit 1
fi

mkdir -p "$output_dir"

get_unique_filename() {
  local dir="$1"
  local filename="$2"
  if [ ! -e "$dir/$filename" ]; then
    printf '%s\n' "$filename"
    return
  fi
  local base="${filename%.*}"
  local ext=""
  if [[ "$filename" == *.* && "$base" != "" ]]; then
    ext=".${filename##*.}"
  fi
  local n=1
  while [ -e "$dir/${base}${n}${ext}" ]; do
    ((n++))
  done
  printf '%s\n' "${base}${n}${ext}"
}

if [ "$max_depth_mode" = true ]; then
  find "$input_dir" -mindepth 1 -maxdepth "$max_depth" | while IFS= read -r path; do
    rel="${path#"$input_dir"/}"
    dest="$output_dir/$rel"
    if [ -d "$path" ]; then
      mkdir -p "$dest"
    elif [ -f "$path" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -p "$path" "$dest"
    fi
  done

else
  find "$input_dir" -type f | while IFS= read -r filepath; do
    name="$(basename "$filepath")"
    unique="$(get_unique_filename "$output_dir" "$name")"
    cp -p "$filepath" "$output_dir/$unique"
  done
fi

exit 0
