#!/usr/bin/env python3

import http.client
import json
import os

# GitHub repository information
USERNAME = os.environ.get('GITHUB_USERNAME')
ACCESS_TOKEN = os.environ.get('GITHUB_ACCESS_TOKEN')

REPO = "RNA-Seq-Nextflow"
REPO = "Cut-and-Tag-Nextflow"

TARGET_COMMITISH = "master"  # Specify the branch or commit hash you want to tag

def get_last_tag(repo_owner, repo_name):
    connection = http.client.HTTPSConnection("api.github.com")
    headers = {"User-Agent": "Python HTTP Client"}
    url = f"/repos/{repo_owner}/{repo_name}/tags"
    
    connection.request("GET", url, headers=headers)
    response = connection.getresponse()
    data = response.read()

    if response.status == 200:
        tags = json.loads(data)
        if tags:
            last_tag_name = tags[0]['name']
            return last_tag_name
        else:
            return "No tags found for the repository."
    else:
        return f"Failed to fetch tags. Status code: {response.status}"

    
def create_tag_object(last_tag):
    # Check if the last commit hash is valid
    last_dot_index = last_tag.rfind('.')
    numeric_part = last_tag[last_dot_index + 1:]
    incremented_numeric_part = str(int(numeric_part) + 1)
    
    # Create the new tag string by replacing the numeric part
    new_tag = last_tag[:last_dot_index + 1] + incremented_numeric_part
    
    tag_object = {
        "tag_name": new_tag,
        "target_commitish": "main",
        "name": f"Release {new_tag}",
        "body": "Release notes and description",
        "draft": False,
        "prerelease": False
    }

    return tag_object



def create_release(username, repo, tag_object, access_token):
    connection = http.client.HTTPSConnection("api.github.com")
    headers = {
        "Authorization": f"token {access_token}",
        "Content-Type": "application/json",
        "User-Agent": "Python HTTP Client"
    }
    url = f"/repos/{username}/{repo}/releases"

    payload = json.dumps(tag_object)

    print(f"{url=}") 
    print(f"{payload=}") 
    print(f"{headers=}") 
    connection.request("POST", url, body=payload, headers=headers)
    response = connection.getresponse()
    data = response.read()

    if response.status == 201:
        return "Release created successfully."
    else:
        return f"Failed to create release. Status code: {response.status}, Response: {data}"

if __name__ == "__main__":     
    print(f"Assess token {ACCESS_TOKEN}")
    last_tag = get_last_tag(USERNAME, REPO)
    print(f"The last tag of the repository is: {last_tag}")
    
    tag_object = create_tag_object(last_tag)
    print(f"The new tag object of the repository is: {tag_object}")

    res_status = create_release(USERNAME, REPO, tag_object, ACCESS_TOKEN)
    print(f"The create_tag res_status is: {res_status}")
     
