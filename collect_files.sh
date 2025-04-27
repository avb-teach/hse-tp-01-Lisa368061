#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 input_dir output_dir [--max_depth depth]"
  exit 1
fi

input_dir="${1%/}"
output_dir="${2%/}"
max_depth_flag=false
max_depth=0

if [ $# -eq 4 ] && [ "$3" = "--max_depth" ]; then
  max_depth_flag=true
  max_depth=$4
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
  
  local base="${filename%.*}"
  local ext="${filename##*.}"
  
  if [[ "$base" == "$ext" ]]; then
    ext=""
  else
    ext=".$ext"
  fi
  
  local counter=1
  while [[ -f "$dir/$base$counter$ext" ]]; do
    ((counter++))
  done
  
  echo "$base$counter$ext"
}

copy_flat() {
  find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    unique_name=$(get_unique_filename "$output_dir" "$filename")
    cp "$file" "$output_dir/$unique_name"
  done
}

copy_with_depth() {
  find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
    path="${file#$input_dir/}"
    dir_path=$(dirname "$path")
    
    depth=$(tr -cd '/' <<< "$dir_path" | wc -c)
    if [[ "$dir_path" == "." ]]; then
      depth=0
    else
      depth=$((depth + 1))
    fi
    
    if (( depth <= max_depth )); then
      target_dir="$output_dir/$dir_path"
      mkdir -p "$target_dir"
      filename=$(basename "$file")
      dest_path="$target_dir/$filename"
    else
      filename=$(basename "$file")
      target_dir="$output_dir"
      dest_path="$target_dir/$filename"
    fi
    
    if [[ -f "$dest_path" ]]; then
      unique_name=$(get_unique_filename "$target_dir" "$filename")
      cp "$file" "$target_dir/$unique_name"
    else
      cp "$file" "$dest_path"
    fi
  done
}

if $max_depth_flag; then
  copy_with_depth
else
  copy_flat
fi

exit 0