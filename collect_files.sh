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

generate_unique_name() {
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

export -f generate_unique_name
find "$input_dir" -type f -print0 | while IFS= read -r -d '' filepath; do
  rel_path="${filepath#$input_dir/}"
  
  IFS='/' read -ra path_parts <<< "$rel_path"
  total_parts=${#path_parts[@]}
  
  filename="${path_parts[$((total_parts-1))]}"
  
  if [ -z "$max_depth" ]; then
    dest_file=$(generate_unique_name "$output_dir" "$filename")
    cp "$filepath" "$output_dir/$dest_file"
  else
    if [ "$total_parts" -gt "$max_depth" ]; then
      start_idx=$((total_parts - max_depth))
    else
      start_idx=0
    fi
    
    target_dir="$output_dir"
    for ((i=start_idx; i<total_parts-1; i++)); do
      target_dir="$target_dir/${path_parts[$i]}"
    done
    
    mkdir -p "$target_dir"
    dest_file=$(generate_unique_name "$target_dir" "$filename")
    cp "$filepath" "$target_dir/$dest_file"
  fi
done

exit 0