#!/bin/bash

# Get Data for GEO
accession_code=$1

wget -qO- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=${accession_code}" | grep "^<Id"| sed 's/<Id>\(.*\)<\/Id>/\1/' >ids.txt

while IFS= read -r id; do
    wget -qO- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id=$id" | jq -r '.result[] | .title, .summary'
done < ids.txt

