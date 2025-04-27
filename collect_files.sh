#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 input_dir output_dir [--max_depth depth]"
  exit 1
fi

input_dir="${1%/}"
output_dir="${2%/}"
max_depth=""

if [ $# -eq 4 ] && [ "$3" = "--max_depth" ]; then
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

find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
  rel_path="${file#$input_dir/}"
  filename="$(basename "$rel_path")"
  dirpath="$(dirname "$rel_path")"
  
  if [ -n "$max_depth" ]; then
    target_dir="$output_dir/$dirpath"
    mkdir -p "$target_dir"
    unique_name=$(get_unique_filename "$target_dir" "$filename")
    cp "$file" "$target_dir/$unique_name"
    
    if [ "$dirpath" != "." ]; then
      IFS='/' read -ra components <<< "$dirpath"
      depth=${#components[@]}
      
      if [ "$depth" -gt "$((max_depth - 1))" ]; then
        components_to_keep=$((max_depth - 1))
        start_idx=$((depth - components_to_keep))
        
        truncated_path=""
        for ((i=start_idx; i<depth; i++)); do
          if [ -z "$truncated_path" ]; then
            truncated_path="${components[$i]}"
          else
            truncated_path="$truncated_path/${components[$i]}"
          fi
        done
        
        trunc_dir="$output_dir/$truncated_path"
        mkdir -p "$trunc_dir"
        unique_trunc=$(get_unique_filename "$trunc_dir" "$filename")
        cp "$file" "$trunc_dir/$unique_trunc"
      fi
    fi
  else
    unique_name=$(get_unique_filename "$output_dir" "$filename")
    cp "$file" "$output_dir/$unique_name"
  fi
done

exit 0