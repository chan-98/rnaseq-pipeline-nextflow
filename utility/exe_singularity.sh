#!/bin/bash
working_dir="/home/daniel.higgins-umw/project_data/RNA-Seq-Nextflow/docs"
cd ${working_dir}
singularity exec -B ${working_dir}:/app/data --pid ${HOME}/.singularity/danhumassmed-qc-tools-1.0.1.img /app/md2pdf.py convert /app/data/overview.md /app/data/overview.css
rm overview.html