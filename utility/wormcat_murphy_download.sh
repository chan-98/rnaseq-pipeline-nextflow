#!/bin/bash
launch_dir="/home/${USER}/project_data/RNA-Seq-Nextflow"
base_dir="${launch_dir}/pipelines/shared/data"

murphy_data="http://www.wormcat.com/static/download/Murphy_TS.xlsx"
mkdir -p ${base_dir}
cd ${base_dir}

wget -nv ${murphy_data}
