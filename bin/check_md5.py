#!/usr/bin/env python3
import os
import sys
import hashlib
import json

# Search for files with name MD5.txt
def search_md5_files(root_directory):
    md5_files = []

    for root, _, files in os.walk(root_directory):
        for file in files:
            if file == "MD5.txt":
                md5_files.append(os.path.join(root, file))

    return md5_files

# Parse the found MD5.txt file and create a JSON with there contents (hash and file name)
def append_md5_to_json(md5_file_path, md5_json):
    try:
        with open(md5_file_path, 'r') as md5_file:
            directory_name = os.path.dirname(md5_file_path)  # Get the directory name
            for line in md5_file:
                parts = line.strip().split("  ")
                if len(parts) == 2:
                    md5_hash, file_name = parts
                    full_path = os.path.join(directory_name, file_name)  # Create the new full path
                    md5_json.append({"hash": md5_hash, "filename": full_path})

    except FileNotFoundError:
        return False  # Handle the file not found error
    except Exception as e:
        return False  # Handle other exceptions

    return True  # Successfully appended to md5_json


# Validate that the hash matches and MD5 check
def verify_hash(md5_dict):
    try:
        provided_hash = md5_dict.get("hash", "")
        filename = md5_dict.get("filename", "")
        result = {"hash": provided_hash, "filename": filename, "passed": False}
        if os.path.exists(filename):
            # Calculate the MD5 hash of the file
            md5_hash = hashlib.md5()
            with open(filename, 'rb') as file:
                while True:
                    data = file.read(8192)  # Read the file in 8KB chunks
                    if not data:
                        break
                    md5_hash.update(data)

            calculated_hash = md5_hash.hexdigest()

            # Compare the provided hash with the calculated hash
            passed = provided_hash == calculated_hash

            # Create a new dictionary with the "passed" field
            result = {"hash": provided_hash, "filename": filename, "passed": passed}
        return result
    except Exception as e:
        return {"error": str(e)}

def create_md5_report(md5_details):
    report = "<html>\n<head>\n\t<title>MD5 Check Report</title>\n</head>\n"
    report += "<body>\n\t<h1>MD5 Check Report</h1>\n\t<table border=1>\n\t\t<tr>\n\t\t\t<th>File</th><th>Status</th>\n\t\t</tr>\n"

    for md5 in md5_details:
        file_name = os.path.basename(md5['filename'])
        status = "<td style='color: green;'>Passed</td>" if md5['passed'] else "<td style='color: red;'>Failed</td>"
        
        report += f"\t\t<tr>\n\t\t\t<td>{file_name}</td>{status}\n\t\t</tr>\n"

    report += "\t</table>\n</body>\n</html>"

    return report


def create_md5_error_report():
    report = "<html>\n<head>\n\t<title>MD5 Check Report</title>\n</head>\n"
    report += "<body>\n<h1>MD5 Check Report failed to process files!</h1>\n"
    report += "<h3>Check that MD5 files are available and are in the correct format.</h3>\n"
    report += "</body>\n</html>"

    return report


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_md5.py <directory_root>")
        sys.exit(1)

    directory_root = sys.argv[1]
    md5_files = search_md5_files(directory_root)

    if md5_files:
        print("MD5.txt files found:")
        md5_json = []
        for md5_file in md5_files:
            append_md5_to_json(md5_file, md5_json)

        md5_checked_json = []
        for md5_dict in md5_json:
            md5_checked_json.append(verify_hash(md5_dict))

        md5_report = create_md5_report(md5_checked_json)
        with open("md5_report.html", "w") as report_file:
            report_file.write(md5_report)

    else:
        error_report = create_md5_error_report()
        with open("md5_report.html", "w") as report_file:
            report_file.write(error_report)

