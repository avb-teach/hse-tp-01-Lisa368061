#!/bin/bash

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 input_dir output_dir [--max_depth depth]"
    exit 1
fi

input_dir="$1"
output_dir="$2"
max_depth_flag=false
max_depth=0

if [[ $# -eq 3 ]]; then
    if [[ "$3" =~ ^--max_depth\ [0-9]+$ ]]; then
        max_depth_flag=true
        max_depth="${3#*--max_depth }"
    else
        echo "Invalid parameter: $3"
        echo "Usage: $0 input_dir output_dir [--max_depth depth]"
        exit 1
    fi
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' does not exist."
    exit 1
fi

if [[ ! -d "$output_dir" ]]; then
    mkdir -p "$output_dir"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create output directory '$output_dir'."
        exit 1
    fi
fi

copy_files() {
    local src_dir="$1"
    local dst_dir="$2"
    local current_depth="$3"
    
    for file in "$src_dir"/*; do
        if [[ ! -e "$file" ]]; then
            continue
        fi
        
        filename=$(basename "$file")
        
        if [[ -f "$file" ]]; then
            if [[ "$max_depth_flag" = false || "$current_depth" -le "$max_depth" ]]; then
                if [[ "$max_depth_flag" = false ]]; then
                    if [[ -f "$dst_dir/$filename" ]]; then
                        counter=1
                        filename_base="${filename%.*}"
                        extension="${filename##*.}"
                        
                        if [[ "$filename_base" = "$filename" ]]; then
                            new_filename="${filename_base}${counter}"
                        else
                            new_filename="${filename_base}${counter}.${extension}"
                        fi
                        
                        while [[ -f "$dst_dir/$new_filename" ]]; do
                            ((counter++))
                            if [[ "$filename_base" = "$filename" ]]; then
                                new_filename="${filename_base}${counter}"
                            else
                                new_filename="${filename_base}${counter}.${extension}"
                            fi
                        done
                        
                        cp "$file" "$dst_dir/$new_filename"
                    else
                        cp "$file" "$dst_dir/$filename"
                    fi
                else
                    cp "$file" "$dst_dir/"
                fi
            fi
        elif [[ -d "$file" ]]; then
            if [[ "$max_depth_flag" = true && "$current_depth" -lt "$max_depth" ]]; then
                mkdir -p "$dst_dir/$filename"
                copy_files "$file" "$dst_dir/$filename" $((current_depth + 1))
            elif [[ "$max_depth_flag" = false ]]; then
                copy_files "$file" "$dst_dir" $((current_depth + 1))
            fi
        fi
    done
}

if [[ "$max_depth_flag" = true ]]; then
    input_base=$(basename "$input_dir")
    mkdir -p "$output_dir"
    copy_files "$input_dir" "$output_dir" 1
else
    copy_files "$input_dir" "$output_dir" 1
fi

echo "Files have been collected from '$input_dir' to '$output_dir'"
exit 0