#!/bin/bash

read_1=$1
read_2=$2
data_root=$3
dir_suffix=$4
trim_control=$5

# Determine the original directory structure for these files
real_path=`readlink -f $read_1`
path_without_filename=$(dirname "$real_path")
path_to_data="trim_${dir_suffix}/${path_without_filename#*$data_root}"

DIR_OUT="trimmed"  # Specify your directory here
SUFFIX_1="*_val_1.fq.gz" # Specify the pattern
SUFFIX_2="*_val_2.fq.gz" # Specify the pattern


find_suffix() {
    local dir=$1
    local pattern=$2
    local file=$(find "$dir" -type f -name "$pattern")
    
    if [[ -n "$file" ]]; then
        local filename=$(basename "$file")
        echo "${filename%${pattern#*}}"
    else
        echo "No matching file found."
    fi
}

rename_file() {
    local DIR=$1
    local PREFIX=$2
    local SUFFIX=$3
    echo $PREFIX
    if [[ "$PREFIX" != "No matching file found." ]]; then
        mv ${DIR}/${PREFIX}${SUFFIX} ${DIR}/T_${PREFIX}.fq.gz  
    else
        echo "No valid file found."
    fi
}

# Recreate the directory structure for the output
mkdir -p "${path_to_data}"

if [[ -z "$read_2" ]]; then
    echo "Variable 2 is empty"
    trim_galore \
        --cores 4 \
        ${trim_control} \
        --output_dir ${DIR_OUT} \
        ${read_1}
else
    echo "Variable 2 is not empty"
    trim_galore \
        --cores 4 \
        --paired \
        ${trim_control} \
        --output_dir ${DIR_OUT} \
        ${read_1} ${read_2}
fi

PREFIX_1=$(find_suffix "$DIR_OUT" "$SUFFIX_1")
rename_file "$DIR_OUT" "$PREFIX_1" "$SUFFIX_1"

PREFIX_2=$(find_suffix "$DIR_OUT" "$SUFFIX_2")
rename_file "$DIR_OUT" "$PREFIX_2" "$SUFFIX_2"

cp ${DIR_OUT}/T_* "${path_to_data}/"


