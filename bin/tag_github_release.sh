#!/bin/bash

# tag_github_release.sh depends on having an initial tag!! 
# The tage must use the naming convention v1.0.0
# The program will increment the last number and create a new release

# Program also requires environment variables to be set
# GITHUB_ACCESS_TOKEN and GITHUB_USERNAME 

# Check that Repo was pass in
if [ -z "$1" ]; then
    echo "Usage: $0 <repo_name>"
    exit 1
 else
    REPO=$1
fi

# Check the envoronment variables are set
if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
    echo "GITHUB_ACCESS_TOKEN is not set."
    exit 1
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo "GITHUB_USERNAME is not set."
    exit 1
fi


increment_version() {
    if [ -z "$1" ]; then
        echo "Usage: increment_version <version>"
        return 1
    fi

    # Extract the version components
    local version="$1"
    local prefix
    local last_digit

    # Split the version string by dot '.'
    prefix=$(echo "$version" | rev | cut -d. -f2- | rev)
    last_digit=$(echo "$version" | rev | cut -d. -f1 | rev)

    # Check if the last component is a valid number
    if ! [[ $last_digit =~ ^[0-9]+$ ]]; then
        echo "Invalid version format: $version"
        return 1
    fi

    # Increment the last digit and reconstruct the version string
    incremented=$((last_digit + 1))
    incremented_version="${prefix}.${incremented}"

    echo "$incremented_version"
}

list_releases() {
    wget -q --header="Accept: application/vnd.github+json" \
     --header="Authorization: Bearer $GITHUB_ACCESS_TOKEN" \
     --header="X-GitHub-Api-Version: 2022-11-28" \
     -O - \
     https://api.github.com/repos/$GITHUB_USERNAME/$REPO/releases

}

create_release2() {
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_USERNAME/$REPO/releases \
  -d '{"tag_name":"v1.0.7","target_commitish":"master","name":"v1.0.7","body":"Description of the release","draft":false,"prerelease":false,"generate_release_notes":false}'
}
create_release() {
    git pull

    last_tag=$(git describe --tags --abbrev=0)
    version=$(increment_version "$last_tag")

    api_json=$(printf '{"tag_name": "%s","target_commitish": "master","name": "%s","body": "Release of version %s","draft": false,"prerelease": false}' $version $version $version)

    wget -q --header="Content-Type: application/json" \
        --header="Authorization: token $GITHUB_ACCESS_TOKEN" \
        --header="User-Agent: Python HTTP Client" \
        --post-data="$api_json" \
        --no-check-certificate \
        -O - \
        https://api.github.com/repos/$GITHUB_USERNAME/$REPO/releases

}

create_tag() {
    echo "Create Tag.."
    git pull
    #last_tag=$(git describe --tags --abbrev=0)
    #version=$(increment_version "$last_tag")
    version="v1.0.1"
    echo "$last_tag to $version"
    git tag -a $version -m "Release of version $version"
    git push --tags
}

create_tag
