#!/bin/bash

project_results=$1
project_data=$2
stage_dir=$3

#current_date=`date '+%b-%d-%Y'`
#stage_dir="Results-${current_date}"

# If the staging directory aready exists recreate it
if [ -d "$stage_dir" ]; then
    echo "Directory exists. Deleting..."
    rm -r "$stage_dir"
fi

sub_dir_list="00-Overview 01-Quality_Control 02-Quantification 03-Differential_Expression 04-Functional_Analysis"
IFS=' ' read -r -a sub_dirs <<< "$sub_dir_list"

for dir in "${sub_dirs[@]}"; do
    mkdir -p ${stage_dir}/${dir}
done

# Function to copy directories
copy_deseq_dirs() {
    local src_dir="$1"
    local dest_dir="$2"

    for dir in "$src_dir"/deseq_*; do
        if [ -d "$dir" ]; then
            cp -r "$dir" "$dest_dir"
        fi
    done
}


# Stage 00-Overview
cp ${project_results}/overview_report.pdf ${stage_dir}/${sub_dirs[0]}/

# Stage 01-Quality_Control
fastqc_dir=${stage_dir}/${sub_dirs[1]}/fastqc 
mkdir -p ${fastqc_dir}
cp ${project_results}/fastqc/**/*.html ${fastqc_dir}/
cp ${project_results}/fastqc/*.html ${stage_dir}/${sub_dirs[1]}/
cp ${project_results}/multiqc_*report.html ${stage_dir}/${sub_dirs[1]}/
cp ${project_results}/md5_report.html ${stage_dir}/${sub_dirs[1]}/

# # Stage 02-Quantification
mkdir -p ${stage_dir}/${sub_dirs[2]}/results
cp ${project_results}/rsem_expression/**/*.results ${stage_dir}/${sub_dirs[2]}/results
cp ${project_results}/rsem_summary/* ${stage_dir}/${sub_dirs[2]}/
cp ${project_results}/low_count_summary/*.tsv ${stage_dir}/${sub_dirs[2]}/
cp ${project_data}/wormbase/*.geneIDs.csv ${stage_dir}/${sub_dirs[2]}/

# Stage 03-Differential_Expression
#find "${project_results}" -type d -name "deseq_*" -exec cp -r {} "${stage_dir}/${sub_dirs[3]}/" \; 
copy_deseq_dirs "$project_results" "${stage_dir}/${sub_dirs[3]}"
cp ${project_results}/deseq_report.pdf ${stage_dir}/${sub_dirs[3]}/  

# Stage 04-Functional_Analysis
cp -r ${project_results}/wormcat/wormcat_* ${stage_dir}/${sub_dirs[4]}/
find ${stage_dir}/${sub_dirs[4]}/ -type f -name "*.zip" -delete
cp -r ${project_results}/wormcat/wormcat_*/**/*.xlsx ${stage_dir}/${sub_dirs[4]}/

