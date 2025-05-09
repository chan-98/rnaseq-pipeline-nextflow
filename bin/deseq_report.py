#!/usr/bin/env python3

import argparse
import glob
import json
import pandas
import os
import markdown
import pandas as pd
from markdown_include.include import MarkdownInclude
from weasyprint import HTML



REPORT_TEMPLATE_FILE = "./deseq_report_template.md"
REPORT_TEMPLATE_CSS = "./report_template.css"
DESEQ_REPORT_MD = "./deseq_report.md"
LOW_COUNTS_FILTERED="./low_count_summary/count_data_low_counts_filtered.tsv"
RSEM_COUNTS="./rsem_summary/genes_expression_expected_count.tsv"
GENE_IDS_PATTERN="./c_elegans.PRJNA13758.*.geneIDs.csv"


def add_title_page(json_file, report_data={}):
    # Extract values from JSON data
    # Read JSON data from file
    with open(json_file, 'r') as file:
        json_data = json.load(file)
    
    prepared_for = ""
    for person in json_data['prepared_for']:
        prepared_for += f"\t* {person} \n"
    
    report_data['title'] = json_data['title'] 
    report_data['process_date'] = json_data['process_date']
    report_data['prepared_by'] = json_data['prepared_by'] 
    report_data['prepared_for'] = prepared_for 
 
    return report_data 


def get_counts_summary(counts_file):
    counts_df = pd.read_csv(counts_file, delimiter='\t')
    counts_df = counts_df.drop('gene_id', axis=1)
    for col in counts_df.columns:
        if pd.api.types.is_numeric_dtype(counts_df[col]):
            counts_df[col] = counts_df[col].astype(int, errors='ignore')

    column_sums = counts_df.sum()
    column_sums = column_sums.sort_index()
    return column_sums

def add_low_counts_filter_table(report_data):
    counts_before = get_counts_summary(RSEM_COUNTS)
    counts_after =get_counts_summary(LOW_COUNTS_FILTERED)
    counts_summary_df = pd.concat([counts_before, counts_after], axis=1, keys=['Before', 'After'])

    html_table  = "<table style= 'width: 600px;'>\n"
    html_table += "\t<tr><th colspan='3' style='background-color: #3e8dbc; color: white;text-align: center;'>Low Count Filter</th></tr>\n"
    html_table += "\t<tr><th>lib-name</th><th>Before</th><th>After</th></tr>\n"
    
    html_rows = ''
    for idx, row in counts_summary_df.iterrows():
        html_rows += f"\t<tr><td>{idx}</td><td>{row['Before']:,}</td><td>{row['After']:,}</td></tr>\n"

    html_table += html_rows
    html_table += "</table>\n" 

    report_data['low_counts_table']= html_table
    return report_data

def add_deseq_run_details(report_data):
    current_dir = './'
    # Get all directories in the specified directory
    all_directories = [d for d in os.listdir(current_dir) if os.path.isdir(os.path.join(current_dir, d))]

    # Filter directories with the prefix 'desk_run'
    prefix = 'deseq_'
    filtered_directories = [d for d in all_directories if d.startswith(prefix)]

    # Display the filtered directories
    print(f"Directories with prefix '{prefix}':")
    html = "<h2>DESeq2 Results</h2>\n"
    experiment = 0
    for directory in filtered_directories:
       experiment += 1
       page_break = "style='page-break-before: always;'" if experiment > 1 else ""
       html += f"<h3 {page_break}>Experiment {directory[6:]}</h3>\n"
       html += top_ten_de(directory, "UP") 
       html += top_ten_de(directory, "DOWN") 
       html += "<br>\n"
       html += add_two_img_div(f"{directory}/plots", f"{directory[6:]}_scatter_plot.png",f"{directory[6:]}_volcano_plot.png") 
       html += "<br>\n"
       html += add_two_img_div(f"{directory}/plots", f"{directory[6:]}_heatmap_plot.png",f"{directory[6:]}_pca_plot.png")
       #html += "<br>\n"
       #html += add_data_image_div(f"{directory}/plots", f"{directory[6:]}_dispersion_plot.svg")

    report_data['differential_results'] = html
    return report_data

def top_ten_de(directory, direction):
    # Derive the directory
    expression_csv = os.path.join(directory, f"ud_{directory[6:]}", f"{direction}.csv")
    expression_df = pd.read_csv(expression_csv)     
    gene_ids_csv = glob.glob(GENE_IDS_PATTERN)[0]
    gene_ids_df = pd.read_csv(gene_ids_csv)     
    expression_df = pd.merge(expression_df, gene_ids_df[['Wormbase_Id', 'Sequence_id', 'Gene_name']], left_on='ID', right_on='Wormbase_Id', how='left') 
    if 'UP' in direction:
        ascending=False
    else: # DOWN
        ascending=True
    expression_df = expression_df.sort_values(by='log2FoldChange', ascending=ascending)

    html = ""
    html +="<table class='bordered-table styled-table' style= 'width: 600px;'>\n"
    html +=f"    <tr><th colspan='4' style='text-align: center;border-bottom: 1px solid white;'>Top 10 {direction} for {directory[6:]}</th></tr>\n"
    html +="    <tr><th>Wormbase_Id</th><th>Sequence_id</th><th>Gene_name</th><th>log2FoldChange</th></tr>\n"
    for index, row in expression_df.head(10).iterrows():
        html +=f"<tr><td>{row['ID']}</td><td>{row['Sequence_id']}</td>"
        html +=f"<td>{row['Gene_name']}</td><td>{row['log2FoldChange']:.4f}</td>\n"
    html +="</table>\n"
    html +="<br>\n"

    return html       

    
def add_data_image_div(base_dir,image):
    html = "<div>\n"
    html +="<table class='bordered-table styled-table'>\n"
    html +="    <tr><th colspan='2' style='text-align: center;border-bottom: 1px solid white;'>Execution Information</th></tr>\n"
    html +="    <tr><th>Name</th><th>Value</th></tr>\n"
    html +="    <tr><td>Dataset: </td><td>alldetected</td></tr>\n"
    html +="    <tr><td>Normalization:</td><td>MRN</td></tr>\n"
    html +="    <tr><td>DESeq2 Params:</td><td>fitType=parametric, betaPrior=FALSE, testType=LRT</td></tr>\n"
    html +="    <tr><td>Heatmap Params:</td><td>Scaled=TRUE, Centered=TRUE, Pseudo-count-0.01</td></tr>\n"
#    html +="    <tr><td>Condition 1:</td><td></td></tr>\n"
#    html +="    <tr><td>Condition 2:</td><td></td></tr>\n"
    html +="</table>\n"
    html += "<br>\n"
    html += f"\t<img src='{base_dir}/{image}' style='width: 65%;'>\n"
    html += "</div>"
    return html


def add_two_img_div(base_dir,image1,image2):
    html = "<div>\n"
    html += f"\t<img src='{base_dir}/{image1}' style='width: 48%;'>\n"
    html += f"\t<img src='{base_dir}/{image2}' style='width: 48%;'>\n"
    html += "</div>"
    return html



def generate_markdown(json_file):
    with open(REPORT_TEMPLATE_FILE, 'r') as file:
        report_template = file.read()

    report_data = {}
    report_data = add_title_page(json_file, report_data)
    report_data = add_low_counts_filter_table(report_data)
    report_data = add_deseq_run_details(report_data)

    markdown_content = report_template.format(title=report_data['title'],
                                              process_date=report_data['process_date'],
                                              prepared_by=report_data['prepared_by'],
                                              prepared_for=report_data['prepared_for'],
                                              low_counts_table=report_data['low_counts_table'],
                                              differential_results=report_data['differential_results'])
 
    

    # Write Markdown content to output file
    with open(DESEQ_REPORT_MD, 'w') as file:
        file.write(markdown_content)

    print("Markdown file generated successfully.")

def convert_to_html(markdown_file_name, css_file_name):
    with open(markdown_file_name, mode="r", encoding="utf-8") as markdown_file:
        with open(css_file_name, mode="r", encoding="utf-8") as css_file:
            markdown_input = markdown_file.read()
            css_input = css_file.read()

            markdown_path = os.path.dirname(markdown_file_name)
            markdown_include = MarkdownInclude(configs={"base_path": markdown_path})
            html = markdown.markdown(
                markdown_input, extensions=["extra", markdown_include, "meta", "tables"]
            )

            return f"""
            <html>
              <head>
                <style>{css_input}</style>
              </head>
              <body>{html}</body>
            </html>
            """

def convert_to_pdf(markdown_file_name, css_file_name):
    
    file_name = os.path.splitext(markdown_file_name)[0]
    html_string = convert_to_html(markdown_file_name, css_file_name)

    with open(
        file_name + ".html", "w", encoding="utf-8", errors="xmlcharrefreplace"
    ) as output_file:
        output_file.write(html_string)

    markdown_path = os.path.dirname(markdown_file_name)
    print(f"{os.path.splitext(markdown_file_name)=}\n{markdown_file_name=}\n{markdown_path=}")
    html = HTML(string=html_string, base_url=markdown_path)
    html.write_pdf(file_name + ".pdf")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--report-config', help='JSON Config file for report')
    parser.add_argument('-i', '--input-path', help='The input path for report data')
    args = parser.parse_args()
    cmd_line_msg = "deseq_report.py --report-config [<report.json>] --input-path [<base_directory>]"
        
    if not args.report_config:
        print(cmd_line_msg)
        print("JSON Config is missing.")
        return
    
    if not args.input_path:
         print(cmd_line_msg)
         print("Input path is missing.")
         return

    generate_markdown(args.report_config)
    convert_to_pdf(DESEQ_REPORT_MD, REPORT_TEMPLATE_CSS)

if __name__ == '__main__':
    main()

