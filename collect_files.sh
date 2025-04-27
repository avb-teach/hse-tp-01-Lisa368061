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
    rel_path="${file#$input_dir/}"
    filename=$(basename "$rel_path")
    dir_path=$(dirname "$rel_path")
    
    full_target_dir="$output_dir/$dir_path"
    mkdir -p "$full_target_dir"
    
    if [[ -f "$full_target_dir/$filename" ]]; then
      unique_name=$(get_unique_filename "$full_target_dir" "$filename")
      cp "$file" "$full_target_dir/$unique_name"
    else
      cp "$file" "$full_target_dir/$filename"
    fi
    
    if [[ "$dir_path" == "." ]]; then
      continue
    fi
    
    IFS='/' read -ra path_parts <<< "$dir_path"
    depth=${#path_parts[@]}
    
    if (( depth >= max_depth )); then
      start_idx=$((max_depth - 2))
      
      if (( start_idx >= 0 )); then
        truncated_parts=()
        for (( i=start_idx; i<depth; i++ )); do
          truncated_parts+=("${path_parts[i]}")
        done
        
        truncated_path=$(IFS=/; echo "${truncated_parts[*]}")
        
        if [[ -n "$truncated_path" ]]; then
          truncated_target_dir="$output_dir/$truncated_path"
          mkdir -p "$truncated_target_dir"
          
          if [[ -f "$truncated_target_dir/$filename" ]]; then
            unique_name=$(get_unique_filename "$truncated_target_dir" "$filename")
            cp "$file" "$truncated_target_dir/$unique_name"
          else
            cp "$file" "$truncated_target_dir/$filename"
          fi
        fi
      fi
    fi
  done
}

if $max_depth_flag; then
  copy_with_depth
else
  copy_flat
fi

exit 0