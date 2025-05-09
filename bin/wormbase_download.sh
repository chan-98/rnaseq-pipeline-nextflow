#!/bin/bash
# Select Version from https://wormbase.org/
 
wormbase_version=$1
echo "Starting Wormbase Download with version $wormbase_version"

base_url="https://downloads.wormbase.org/releases/${wormbase_version}/species/c_elegans/PRJNA13758"
#base_url="ftp://ftp.wormbase.org/pub/wormbase/releases/${wormbase_version}/species/c_elegans/PRJNA13758"
genes_fasta="c_elegans.PRJNA13758.${wormbase_version}.genomic.fa.gz"
transcripts_fasta="c_elegans.PRJNA13758.${wormbase_version}.mRNA_transcripts.fa.gz"
annotations_gtf="c_elegans.PRJNA13758.${wormbase_version}.canonical_geneset.gtf.gz"
gene_ids="c_elegans.PRJNA13758.${wormbase_version}.geneIDs.txt.gz"

wget -nv ${base_url}/${genes_fasta}
wget -nv ${base_url}/${transcripts_fasta}
wget -nv ${base_url}/${annotations_gtf}
wget -nv ${base_url}/annotation/${gene_ids}
gunzip --force ${genes_fasta}
gunzip --force ${transcripts_fasta}
gunzip --force ${annotations_gtf}
gunzip --force ${gene_ids}

# Create GeneIDs.csv
gene_ids_txt=$(echo "$gene_ids" | sed 's/.\{3\}$//')
gene_ids_csv=$(echo "$gene_ids" | sed 's/.\{7\}$//')
gene_ids_csv="${gene_ids_csv}.csv"

awk -F',' '$5=="Live" {print $2","$3","$4","$6}' "$gene_ids_txt" > "$gene_ids_csv"
sed -i '1iWormbase_Id,Gene_name,Sequence_id,Gene_Type' "$gene_ids_csv"
