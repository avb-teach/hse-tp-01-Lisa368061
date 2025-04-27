#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Использование: $0 input_dir output_dir [--max_depth depth]"
  exit 1
fi

input_dir="$1"
output_dir="$2"
max_depth_flag=false
max_depth=0

if [ $# -eq 4 ] && [ "$3" = "--max_depth" ]; then
  max_depth_flag=true
  max_depth=$4
fi

if [ ! -d "$input_dir" ]; then
  echo "Ошибка: Входная директория '$input_dir' не существует"
  exit 1
fi

mkdir -p "$output_dir"

get_unique_filename() {
  local dir="$1"
  local filename="$2"
  
  if [ ! -f "$dir/$filename" ]; then
    echo "$filename"
    return
  fi
  
  if [[ "$filename" == *.* ]]; then
    local base="${filename%.*}"
    local ext=".${filename##*.}"
  else
    local base="$filename"
    local ext=""
  fi
  
  local counter=1
  while [ -f "$dir/$base$counter$ext" ]; do
    ((counter++))
  done
  
  echo "$base$counter$ext"
}

copy_flat() {
  find "$input_dir" -type f | while read -r file; do
    filename=$(basename "$file")
    unique_name=$(get_unique_filename "$output_dir" "$filename")
    cp "$file" "$output_dir/$unique_name"
  done
}

copy_with_depth() {
  find "$input_dir" -mindepth 1 | while read -r item; do
    if [ "$item" = "$input_dir" ]; then
      continue
    fi
    
    rel_path="${item#$input_dir/}"
    
    depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
    
    if [ "$depth" -lt "$max_depth" ]; then
      dest_path="$output_dir/$rel_path"
      
      if [ -d "$item" ]; then
        mkdir -p "$dest_path"
      elif [ -f "$item" ]; then
        parent_dir=$(dirname "$dest_path")
        mkdir -p "$parent_dir"
        
        cp "$item" "$dest_path"
      fi
    fi
  done
}

if [ "$max_depth_flag" = true ]; then
  copy_with_depth
else
  copy_flat
fi

exit 0
