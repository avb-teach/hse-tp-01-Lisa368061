#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 input_dir output_dir [--max_depth depth]"
  exit 1
fi

input_dir="${1%/}"
output_dir="${2%/}"
max_depth=""

if [ $# -ge 4 ] && [ "$3" = "--max_depth" ]; then
  max_depth=$4
  if ! [[ "$max_depth" =~ ^[0-9]+$ ]] || [ "$max_depth" -le 0 ]; then
    echo "Error: --max_depth requires a positive integer"
    exit 1
  fi
fi

if [ ! -d "$input_dir" ]; then
  echo "Error: Input directory '$input_dir' does not exist"
  exit 1
fi

mkdir -p "$output_dir"

get_unique_filename() {
  local dir="$1"
  local filename="$2"
  
  if [[ ! -f "$dir/$filename" ]]; then
    echo "$filename"
    return
  fi
  
  local base ext
  if [[ "$filename" == *.* ]]; then
    base="${filename%.*}"
    ext=".${filename##*.}"
  else
    base="$filename"
    ext=""
  fi
  
  local counter=1
  while [[ -f "$dir/$base$counter$ext" ]]; do
    ((counter++))
  done
  
  echo "$base$counter$ext"
}

process_file() {
  local target_dir="$1"
  local file="$2"
  local filename="$3"
  
  mkdir -p "$target_dir" || return 1
  unique_name=$(get_unique_filename "$target_dir" "$filename")
  cp "$file" "$target_dir/$unique_name" || echo "Failed to copy $file to $target_dir"
}

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
  rel_path="${file#$input_dir/}"
  filename="$(basename "$rel_path")"
  dirpath="$(dirname "$rel_path")"

  if [ -n "$dirpath" ]; then
    process_file "$output_dir/$dirpath" "$file" "$filename"
  else
    process_file "$output_dir" "$file" "$filename"
  fi

  if [ -n "$max_depth" ]; then
    IFS='/' read -ra path_parts <<< "$dirpath"
    path_length=${#path_parts[@]}
    
    if [ "$path_length" -gt "$max_depth" ]; then
      trunc_start=$((path_length - max_depth))
      trunc_parts=("${path_parts[@]:$trunc_start}")
      trunc_path="$(IFS=/; echo "${trunc_parts[*]}")"
      process_file "$output_dir/$trunc_path" "$file" "$filename"
    fi
  fi
done

exit 0