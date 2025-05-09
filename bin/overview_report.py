#!/usr/bin/env python3

import argparse
import subprocess
import json
import sys
import os
import markdown
from markdown_include.include import MarkdownInclude
from weasyprint import HTML


REPORT_TEMPLATE_FILE = "overview_report_template.md"
REPORT_TEMPLATE_CSS  = "report_template.css"
OVERVIEW_REPORT_MD   = "overview_report.md"


def get_dropbox_link(remote_location):
    # rclone command to get dropbox link
    command = f'rclone --config="rclone.conf" link remote:"{remote_location}"'

    try:
        output = subprocess.check_output(command, shell=True, text=True)
        dropbox_link = output.strip()
        return dropbox_link
    except subprocess.CalledProcessError as e:
        return f"Error: {str(e)}"

def get_fastq_names(remote_location):
    # rclone command to get fastq files
    # command = f'rclone --config="rclone.conf" lsl remote:"{remote_location}" --human-readable|grep .fq.gz|sed "s/\.000000000//"'
    command = f'rclone --config="rclone.conf" lsl remote:"{remote_location}" --human-readable | grep -E "\\.fq\\.gz$|\\.fastq\\.gz$" | sed "s/\\.000000000//"'

    try:
        output = subprocess.check_output(command, shell=True, text=True)
        return output
    except subprocess.CalledProcessError as e:
         return f"Error: {str(e)}"


def generate_markdown(json_file):
    # Read JSON data from file
    with open(json_file, 'r') as file:
        json_data = json.load(file)

    with open(REPORT_TEMPLATE_FILE, 'r') as file:
        report_template = file.read()

    # Extract values from JSON data
    title = json_data['title']
    process_date = json_data['process_date']
    prepared_by = json_data['prepared_by']
    prepared_for = ""
    for person in json_data['prepared_for']:
        prepared_for += f"\t* {person} \n"
    
    dropbox_folder = json_data['dropbox_folder']
    dropbox_link = get_dropbox_link(dropbox_folder)
    fastq_files = get_fastq_names(dropbox_folder)
    wormbase_version = json_data['wormbase_version']
    github_release = json_data['github_release']
    github_tag = json_data['github_tag']
    pipeline_config = json_data['pipeline_config']

    markdown_content = report_template.format(title=title,
                                              process_date=process_date,
                                              prepared_by=prepared_by,
                                              prepared_for=prepared_for,
                                              dropbox_folder=dropbox_folder,
                                              dropbox_link=dropbox_link,
                                              fastq_files=fastq_files,
                                              wormbase_version=wormbase_version,
                                              github_release=github_release,
                                              github_tag=github_tag,
                                              pipeline_config=pipeline_config)

    # Write Markdown content to output file
    with open(OVERVIEW_REPORT_MD, 'w') as file:
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

def convert_to_pdf():
    file_name = os.path.splitext(OVERVIEW_REPORT_MD)[0]
    html_string = convert_to_html(OVERVIEW_REPORT_MD, REPORT_TEMPLATE_CSS)

    with open(
        file_name + ".html", "w", encoding="utf-8", errors="xmlcharrefreplace"
    ) as output_file:
        output_file.write(html_string)

    markdown_path = os.path.dirname(OVERVIEW_REPORT_MD)
    html = HTML(string=html_string, base_url=markdown_path)
    html.write_pdf(file_name + ".pdf")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--report-config', help='JSON Config file for report')
    #parser.add_argument('-o', '--output-path', help='The outpout path for the report')
    args = parser.parse_args()
    cmd_line_msg = "overview_report.py --report-config [<report.json>] --output-path [<base_directory>]"
        
    if not args.report_config:
        print(cmd_line_msg)
        print("JSON Config is missing.")
        return
    
    # if not args.output_path:
    #     print(cmd_line_msg)
    #     print("Ouput path is missing.")
    #     return

    generate_markdown(args.report_config)
    convert_to_pdf()

if __name__ == '__main__':
    main()

