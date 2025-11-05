#!/bin/bash

# Convert all .md files to .docx using pandoc
# Usage: ./convert-md-to-docx.sh [directory]
# If no directory specified, uses current directory

TARGET_DIR="${1:-.}"

echo "Converting markdown files in: $TARGET_DIR"
echo "----------------------------------------"

# Counter for files processed
count=0

# Find all .md files and convert them
for mdfile in "$TARGET_DIR"/*.md; do
    # Check if any .md files exist
    if [ ! -e "$mdfile" ]; then
        echo "No .md files found in $TARGET_DIR"
        exit 1
    fi
    
    # Get the base filename without extension
    basename="${mdfile%.md}"
    
    # Create the output filename
    docxfile="${basename}.docx"
    
    echo "Converting: $(basename "$mdfile") → $(basename "$docxfile")"
    
    # Run pandoc conversion
    if pandoc -f markdown -t docx -o "$docxfile" "$mdfile"; then
        echo "  ✓ Success"
        ((count++))
    else
        echo "  ✗ Failed"
    fi
done

echo "----------------------------------------"
echo "Converted $count file(s)"
