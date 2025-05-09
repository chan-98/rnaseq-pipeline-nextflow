#!/bin/bash

source_dir="./trim_*"
target_dir="./trimmed"

mkdir -p "$target_dir"
for dir in ${source_dir};
    # Copy the target directories recursively (-r) 
    # and do not clobber (-n) if directory name already exists 
    do cp -rn ${dir}/* ${target_dir}; 
done