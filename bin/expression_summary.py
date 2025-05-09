#!/usr/bin/env python3

import pandas as pd
import os
import argparse

def extract_rsem_experiment_name(file_path):
    file_name = os.path.basename(file_path)
    experiment_name = file_name[5:-14]
    return experiment_name

def extract_salmon_experiment_name(file_path):
    SALMON_PREFIX= "salmon_expression_"
    directory_path = os.path.dirname(file_path)
    index = directory_path.find(SALMON_PREFIX)+len(SALMON_PREFIX)
    experiment_name = directory_path[index:]
    return experiment_name

def find_files_with_suffix(directory, dir_prefix, file_suffix):
    matching_files = []
    for root, dirs, files in os.walk(directory,followlinks=True):
        if dir_prefix in root:
            print(f"{root=}")
            for file in files:
                if file.endswith(file_suffix):
                    matching_files.append(os.path.join(root, file))
    return matching_files

def aggregate_expression_counts(input_path, execution_variables):
    experiment_data_dfs = []
    
    results_files = find_files_with_suffix(input_path, execution_variables['dir_prefix'], execution_variables['file_suffix'])
    # Read in all the individual results from RSEM
    for  result_file in results_files:
        df = pd.read_csv(result_file, delimiter='\t')
        df = df.drop(columns=[col for col in df.columns if col not in execution_variables['columns_to_keep']])
        experiment_name = execution_variables['extract_experiment_name'](result_file)
        df = df.rename(columns={execution_variables['columns_to_keep'][1]: experiment_name})
        experiment_data_dfs.append(df)

    # Aggregate the expected_counts from each file
    merged_df = experiment_data_dfs[0]
    for index in range(1,len(experiment_data_dfs)):
        merged_df = merged_df.merge(experiment_data_dfs[index], on=execution_variables['columns_to_keep'][0], how='left')
    
    
    if execution_variables['expression_type']=='salmon':
        chromosomes = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        merged_df = merged_df[~merged_df['Name'].isin(chromosomes)]

    # Write the results in tsv format
    merged_df.to_csv(f"{execution_variables['output_file']}", sep='\t', index=False)
    return merged_df


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--expression-type', help='Expression type [rsem | salmon]')
    parser.add_argument('-p', '--input-path', help='Input path')
    args = parser.parse_args()
    cmd_line_msg = "expression_summary.py --expression-type [rsem | salmon] --input-path [<base_directory>]"
    execution_variables = {
        'rsem':{'output_file':"genes_expression_expected_count.tsv",
                'dir_prefix':'rsem_',
                'file_suffix':'genes.results',
                'columns_to_keep':['gene_id', 'expected_count'],
                'expression_type' : 'rsem',
                'extract_experiment_name': extract_rsem_experiment_name
                },
        'salmon':{'output_file':"transcript_expression_counts.tsv",
                'dir_prefix':'salmon_',
                'file_suffix':'quant.sf',
                'columns_to_keep':['Name', 'NumReads'],
                'expression_type' : 'salmon',
                'extract_experiment_name': extract_salmon_experiment_name
                }
    }

    if not args.input_path:
        print(cmd_line_msg)
        print("Input path is missing.")
        return
    
    if not args.expression_type:
        print(cmd_line_msg)
        print("Expression type [rsem | salmon] is missing.")
        return
    elif args.expression_type not in ['rsem', 'salmon']:
        print(cmd_line_msg)
        print("Expression type must be [rsem | salmon].")
        return

    # Rest of your program logic goes here
    print("Input path:", args.input_path)
    print("Expression type:", args.expression_type)
    aggregate_expression_counts(args.input_path, execution_variables[args.expression_type])

if __name__ == '__main__':
    main()
