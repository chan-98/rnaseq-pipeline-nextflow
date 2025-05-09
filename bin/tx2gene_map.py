#!/usr/bin/env python

import os
import argparse

def get_transcript(line):
    word = line.split()[0][1:]
    return word

def get_gene(line):
    start_index = line.find("gene=") + len("gene=")
    end_index = len(line)
    word = line[start_index:end_index].strip()
    return word
    
def tx2gene(input_file, output_file):

    with open(input_file, "r") as file:
        # Read lines and filter lines starting with '>'
        lines = [line.strip() for line in file if line.startswith(">")]

    output_lines = []
    for line in lines:
        transcript = get_transcript(line)
        gene = get_gene(line)
        if len(gene):
            output_line = f"{transcript}\t{gene}"
            output_lines.append(output_line)

    # Open the output file for writing
    with open(output_file, "w") as file:
        # Write the filtered header lines to the output file
        file.write("\n".join(output_lines))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input-file', help='fasta file with with gene name annotation')
    parser.add_argument('-o', '--output-file', help='Output file name')
    args = parser.parse_args()
    cmd_line_msg="tx2gene_map.py --input-file [<path_to_input_fasta_file>] --output-file [<output_file_name>]"
    if not args.input_file:
        print(cmd_line_msg)
        print("Input file is missing.")
        return
    
    elif not args.output_file:
        print(cmd_line_msg)
        print("Output file name is missing")
        return

    tx2gene(args.input_file, args.output_file)

if __name__ == '__main__':
    main()
