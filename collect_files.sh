#!/usr/bin/env bash


set -euo pipefail

usage() {
  echo "Usage: $0 input_dir output_dir [--max_depth N]"
  exit 1
}

if [ $# -lt 2 ]; then
  usage
fi

input_dir=${1%/}
output_dir=${2%/}
shift 2

max_depth=""
if [ $# -eq 2 ] && [ "$1" = "--max_depth" ]; then
  if ! [[ "$2" =~ ^[0-9]+$ ]] || [ "$2" -le 0 ]; then
    echo "Error: --max_depth requires a positive integer"
    exit 1
  fi
  max_depth=$2
fi

if [ ! -d "$input_dir" ]; then
  echo "Error: Input directory '$input_dir' does not exist"
  exit 1
fi

mkdir -p "$output_dir"

get_unique_name() {
  local dir="$1" filename="$2"
  local base ext candidate counter=1
  if [[ "$filename" == *.* ]]; then
    base="${filename%.*}"
    ext=".${filename##*.}"
  else
    base="$filename"
    ext=""
  fi
  candidate="${base}${ext}"
  while [ -e "$dir/$candidate" ]; do
    candidate="${base}${counter}${ext}"
    ((counter++))
  done
  printf '%s' "$candidate"
}

export input_dir output_dir max_depth
find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
  rel_path="${file#$input_dir/}"
  dirpath="$(dirname "$rel_path")"
  filename="$(basename "$rel_path")"

  if [ -n "$max_depth" ]; then
    if [ "$dirpath" = "." ]; then
      depth=1
    else
      depth=$(( $(echo "$dirpath" | awk -F"/" '{print NF}') + 1 ))
    fi

    if [ "$depth" -le "$max_depth" ]; then
      target_dir="$output_dir/$dirpath"
    else
      last_dir="$(basename "$dirpath")"
      target_dir="$output_dir/$last_dir"
    fi
  else
    target_dir="$output_dir"
  fi

  mkdir -p "$target_dir"
  unique_name=$(get_unique_name "$target_dir" "$filename")
  cp "$file" "$target_dir/$unique_name"
done
