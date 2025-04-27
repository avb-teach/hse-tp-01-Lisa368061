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
  find "$input_dir" -type d | while read -r dir; do
    if [ "$dir" = "$input_dir" ]; then
      continue
    fi
    
    rel_path="${dir#$input_dir/}"
    
    depth=0
    if [ -n "$rel_path" ]; then
      depth=$(echo "$rel_path" | grep -o "/" | wc -l)
      depth=$((depth + 1)) 
    fi
    
    if [ "$depth" -le "$max_depth" ]; then
      mkdir -p "$output_dir/$rel_path"
    fi
  done
  
  find "$input_dir" -type f | while read -r file; do
    rel_path="${file#$input_dir/}"
    dir_path=$(dirname "$rel_path")
    
    depth=0
    if [ "$dir_path" != "." ]; then
      depth=$(echo "$dir_path" | grep -o "/" | wc -l)
      depth=$((depth + 1))  
    fi
    
    if [ "$depth" -le "$max_depth" ]; then
      dest_dir="$output_dir/$dir_path"
      mkdir -p "$dest_dir"
      cp "$file" "$dest_dir/$(basename "$file")"
    else
      filename=$(basename "$file")
      unique_name=$(get_unique_filename "$output_dir" "$filename")
      cp "$file" "$output_dir/$unique_name"
    fi
  done

  find "$input_dir" -mindepth 2 -type d | while read -r dir; do
    rel_path="${dir#$input_dir/}"
    
    depth=0
    if [ -n "$rel_path" ]; then
      depth=$(echo "$rel_path" | grep -o "/" | wc -l)
      depth=$((depth + 1)) 
    fi
    
    if [ "$depth" -gt "$max_depth" ]; then
      continue
    fi
    
    dir_name=$(basename "$dir")
    
    new_root="$output_dir/$dir_name"
    
    if [ -d "$new_root" ]; then
      continue
    fi
    
    mkdir -p "$new_root"
    
    remaining_depth=$((max_depth - depth + 1))
    
    find "$dir" -maxdepth $remaining_depth | while read -r item; do
      if [ "$item" = "$dir" ]; then
        continue
      fi
      
      rel_item="${item#$dir/}"
      
      if [ -d "$item" ]; then
        mkdir -p "$new_root/$rel_item"
      elif [ -f "$item" ]; then
        dest_dir="$new_root/$(dirname "$rel_item")"
        mkdir -p "$dest_dir"
        cp "$item" "$dest_dir/$(basename "$item")"
      fi
    done
  done
}

if [ "$max_depth_flag" = true ]; then
  copy_with_depth
else
  copy_flat
fi

exit 0