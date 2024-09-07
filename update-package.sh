#!/bin/bash

# Package name and new version to update
PACKAGE_NAME=$1
NEW_VERSION=$2

# Function to update package version in a package.json file
update_package_version() {
    FILE=$1
    PACKAGE=$2
    VERSION=$3
    FOLDER=$(dirname "$FILE")  # Get the folder containing the package.json

    # Check if the package exists in dependencies or devDependencies
    if grep -q "\"$PACKAGE\"" "$FILE"; then
        echo "Updating $PACKAGE in $FILE to version $VERSION"

        # Use 'jq' to replace the version in both dependencies and devDependencies if it exists
        jq "if .dependencies.\"$PACKAGE\" then .dependencies.\"$PACKAGE\" = \"$VERSION\" else . end |
            if .devDependencies.\"$PACKAGE\" then .devDependencies.\"$PACKAGE\" = \"$VERSION\" else . end" \
            "$FILE" > tmp.json && mv tmp.json "$FILE"

        # Navigate to the folder, remove package-lock.json, and run npm install
        cd "$FOLDER" || exit
        echo "Removing package-lock.json and node_modules..."
        rm -f package-lock.json
        rm -rf node_modules

        echo "Running npm install in $FOLDER"
        npm install

        # Delete node_modules after installation
        echo "Deleting node_modules after installation..."
        rm -rf node_modules

        # Return to the original folder
        cd - || exit
    else
        echo "$PACKAGE not found in $FILE"
    fi
}

# Search for all package.json files and update the specified package
find . -name 'package.json' | while read PACKAGE_FILE; do
    update_package_version "$PACKAGE_FILE" "$PACKAGE_NAME" "$NEW_VERSION"
done

echo "Package version update complete!"
